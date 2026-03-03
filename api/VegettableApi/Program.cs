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

// Memory Cache (快取農業部回傳資料，避免重複呼叫)
builder.Services.AddMemoryCache(options =>
{
    options.SizeLimit = 256; // 最多快取 256 筆查詢結果
});

// HttpClient for MOA Open Data
builder.Services.AddHttpClient<IMoaApiService, MoaApiService>(client =>
{
    client.BaseAddress = new Uri("https://data.moa.gov.tw/");
    client.Timeout = TimeSpan.FromSeconds(30);
    client.DefaultRequestHeaders.Add("Accept", "application/json");
});

// Application services
builder.Services.AddScoped<IProductService, ProductService>();

// CORS — 允許前端跨域呼叫
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy
            .AllowAnyOrigin()          // 開發階段允許所有來源
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

var app = builder.Build();

// --- Middleware Pipeline ---

app.UseMiddleware<ExceptionMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "當令蔬果生鮮 API v1");
        c.RoutePrefix = string.Empty; // Swagger UI 直接在根路徑
    });
}

app.UseCors("AllowFrontend");
app.MapControllers();

// Health Check — 前端可用於偵測後端是否存活
app.MapGet("/health", () => Results.Ok(new
{
    status = "healthy",
    timestamp = DateTimeOffset.UtcNow,
    version = "1.0.0",
}));

app.Run();
