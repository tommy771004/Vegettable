using System.Security.Cryptography;

namespace VegettableApi.Middleware;

/// <summary>
/// ETag / If-None-Match 中介層 — GET 回應自動加上 ETag，客戶端帶回時比對，
/// 若內容未變回傳 304 Not Modified 節省頻寬。
/// </summary>
public class ETagMiddleware
{
    private readonly RequestDelegate _next;

    public ETagMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context)
    {
        // 僅處理 GET 請求
        if (!HttpMethods.IsGet(context.Request.Method))
        {
            await _next(context);
            return;
        }

        // 攔截 response body
        var originalStream = context.Response.Body;
        using var memoryStream = new MemoryStream();
        context.Response.Body = memoryStream;

        await _next(context);

        // 只處理成功回應 (2xx)
        if (context.Response.StatusCode is >= 200 and < 300
            && memoryStream.Length > 0
            && !context.Response.Headers.ContainsKey("ETag"))
        {
            memoryStream.Position = 0;
            var hash = await SHA256.HashDataAsync(memoryStream);
            var etag = $"\"{Convert.ToBase64String(hash)[..22]}\"";

            context.Response.Headers.ETag = etag;
            context.Response.Headers.CacheControl = "no-cache"; // 每次仍須驗證

            // 比對 If-None-Match
            if (context.Request.Headers.IfNoneMatch.ToString() == etag)
            {
                context.Response.StatusCode = StatusCodes.Status304NotModified;
                context.Response.ContentLength = 0;
                // 不寫 body
                context.Response.Body = originalStream;
                return;
            }
        }

        // 寫回原始流
        memoryStream.Position = 0;
        context.Response.Body = originalStream;
        await memoryStream.CopyToAsync(originalStream);
    }
}
