using System.Threading.RateLimiting;
using Microsoft.EntityFrameworkCore;
using VegettableApi.Data;
using VegettableApi.Services;
using VegettableApi.Middleware;

var builder = WebApplication.CreateBuilder(args);

// --- Services ---

builder.Services.AddControllers();
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

// --- Database (SQLite) ---
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite("Data Source=vegettable.db"));

// Memory Cache (快取農業部回傳資料，避免重複呼叫)
builder.Services.AddMemoryCache(options =>
{
    options.SizeLimit = 256;
});

// HttpClient for MOA Open Data
builder.Services.AddHttpClient<IMoaApiService, MoaApiService>(client =>
{
    client.BaseAddress = new Uri("https://data.moa.gov.tw/");
    client.Timeout = TimeSpan.FromSeconds(30);
    client.DefaultRequestHeaders.Add("Accept", "application/json");
});

// --- Application services ---
builder.Services.AddScoped<IProductService, ProductService>();
builder.Services.AddScoped<IMarketService, MarketService>();
builder.Services.AddScoped<IAlertService, AlertService>();
builder.Services.AddScoped<IPredictionService, PredictionService>();

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
                    "https://www.vegettable.app",
                    "exp://localhost:8081")
                .AllowAnyHeader()
                .AllowAnyMethod()
                .AllowCredentials();
        }
    });
});

var app = builder.Build();

// --- 自動建立/遷移資料庫 ---
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.EnsureCreatedAsync();
}

// --- Middleware Pipeline ---

// 安全性標頭 (最先執行)
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
        "seasonal", "recipes", "rate-limiting", "sqlite"
    },
}));

app.Run();
