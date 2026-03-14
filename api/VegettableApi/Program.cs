using System.IO.Compression;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.ResponseCompression;
using Microsoft.EntityFrameworkCore;
using VegettableApi.Data;
using VegettableApi.Services;
using VegettableApi.Middleware;

var builder = WebApplication.CreateBuilder(args);

// --- 日誌設定 — 生產環境縮減輸出 ---
builder.Logging.SetMinimumLevel(
    builder.Environment.IsDevelopment() ? LogLevel.Debug : LogLevel.Warning);

// --- Services ---

builder.Services.AddControllers();
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new Asp.Versioning.ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true;
    options.ApiVersionReader = new Asp.Versioning.UrlSegmentApiVersionReader();
}).AddApiExplorer(options =>
{
    options.GroupNameFormat = "'v'VVV";
    options.SubstituteApiVersionInUrl = true;
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "當令蔬果生鮮 API",
        Version = "v1",
        Description = "台灣農產品即時行情查詢 API — 整合農業部開放資料平臺",
    });
});

// --- Database (SQLite with WAL mode for better concurrency) ---
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite("Data Source=vegettable.db"));

// Memory Cache (快取農業部回傳資料，避免重複呼叫)
builder.Services.AddMemoryCache(options =>
{
    options.SizeLimit = 256;
});

// 分散式快取介面（目前使用記憶體實作，可替換為 Redis）
builder.Services.AddDistributedMemoryCache();

// HttpClient for MOA Open Data
builder.Services.AddHttpClient<IMoaApiService, MoaApiService>(client =>
{
    client.BaseAddress = new Uri("https://data.moa.gov.tw/");
    client.Timeout = TimeSpan.FromSeconds(30);
    client.DefaultRequestHeaders.Add("Accept", "application/json");
});

// 回應壓縮 (Gzip/Brotli — 降低傳輸量)
builder.Services.AddResponseCompression(options =>
{
    options.EnableForHttps = true;
    options.Providers.Add<BrotliCompressionProvider>();
    options.Providers.Add<GzipCompressionProvider>();
    options.MimeTypes = ResponseCompressionDefaults.MimeTypes.Concat(
        new[] { "application/json" });
});
builder.Services.Configure<BrotliCompressionProviderOptions>(options =>
    options.Level = CompressionLevel.Fastest);
builder.Services.Configure<GzipCompressionProviderOptions>(options =>
    options.Level = CompressionLevel.Fastest);

// HttpClient for Expo Push Notifications (避免 HttpClient 洩漏)
builder.Services.AddHttpClient("ExpoPush", client =>
{
    client.Timeout = TimeSpan.FromSeconds(10);
    client.DefaultRequestHeaders.Add("Accept", "application/json");
});

// --- Application services ---
builder.Services.AddScoped<IProductService, ProductService>();
builder.Services.AddScoped<IMarketService, MarketService>();
builder.Services.AddScoped<IAlertService, AlertService>();
builder.Services.AddScoped<IPredictionService, PredictionService>();
builder.Services.AddScoped<IFishService, FishService>();
builder.Services.AddScoped<ILivestockService, LivestockService>();
builder.Services.AddScoped<IOrganicService, OrganicService>();

// Background service — 定時同步農業部資料 & 檢查價格警示
builder.Services.AddHostedService<DataFetchBackgroundService>();

// --- Rate Limiting (DDoS / 暴力呼叫防護) ---
builder.Services.AddRateLimiter(options =>
{
    // 全域: 每個 IP 每分鐘最多 60 次請求
    options.AddPolicy("PerIp", context =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 60,
                Window = TimeSpan.FromMinutes(1),
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 5,
            }));

    // 寫入操作 (POST/PUT/DELETE): 每個 IP 每分鐘最多 10 次
    options.AddPolicy("WriteOps", context =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 10,
                Window = TimeSpan.FromMinutes(1),
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 2,
            }));

    // 全域滑動視窗: 每個 IP 每 10 秒最多 20 次
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
        RateLimitPartition.GetSlidingWindowLimiter(
            partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            factory: _ => new SlidingWindowRateLimiterOptions
            {
                PermitLimit = 20,
                Window = TimeSpan.FromSeconds(10),
                SegmentsPerWindow = 2,
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 3,
            }));

    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.OnRejected = async (context, ct) =>
    {
        context.HttpContext.Response.ContentType = "application/json; charset=utf-8";
        var response = new { success = false, message = "請求過於頻繁，請稍後再試 (Too Many Requests)" };
        await context.HttpContext.Response.WriteAsJsonAsync(response, ct);
    };
});

// CORS — 允許前端跨域呼叫
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        if (builder.Environment.IsDevelopment())
        {
            policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
        }
        else
        {
            policy
                .WithOrigins(
                    "https://vegettable.app",
                    "https://www.vegettable.app")
                .AllowAnyHeader()
                .AllowAnyMethod()
                .AllowCredentials();
        }
    });
});

var app = builder.Build();

// --- 自動建立/遷移資料庫 + 啟用 WAL 模式 ---
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.EnsureCreatedAsync();

    // WAL 模式 — 提升讀寫併發性
    await db.Database.ExecuteSqlRawAsync("PRAGMA journal_mode=WAL;");
    await db.Database.ExecuteSqlRawAsync("PRAGMA synchronous=NORMAL;");
}

// --- Middleware Pipeline ---

// 回應壓縮 (最先執行以壓縮所有回應)
app.UseResponseCompression();

// ETag / 304 — 減少重複傳輸
app.UseMiddleware<ETagMiddleware>();

// 安全性標頭
app.UseMiddleware<SecurityHeadersMiddleware>();

// 全域例外處理
app.UseMiddleware<ExceptionMiddleware>();

// Rate Limiting
app.UseRateLimiter();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "當令蔬果生鮮 API v1");
        c.RoutePrefix = string.Empty;
    });
}

app.UseCors("AllowFrontend");
app.MapControllers().RequireRateLimiting("PerIp");

// Health Check
app.MapGet("/health", () => Results.Ok(new
{
    status = "healthy",
    timestamp = DateTimeOffset.UtcNow,
    version = "2.0.0",
    features = new[]
    {
        "products", "markets", "alerts", "prediction",
        "seasonal", "recipes", "fish", "livestock", "organic",
        "rate-limiting", "sqlite"
    },
}));

app.Run();
