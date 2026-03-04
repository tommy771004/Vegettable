namespace VegettableApi.Middleware;

/// <summary>
/// 安全性 HTTP 標頭中介層 — 防止 XSS、Clickjacking、MIME sniffing 等攻擊
/// </summary>
public class SecurityHeadersMiddleware
{
    private readonly RequestDelegate _next;

    public SecurityHeadersMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context)
    {
        var headers = context.Response.Headers;

        // 防止 MIME type sniffing
        headers["X-Content-Type-Options"] = "nosniff";

        // 防止 Clickjacking
        headers["X-Frame-Options"] = "DENY";

        // XSS 保護
        headers["X-XSS-Protection"] = "1; mode=block";

        // 禁止瀏覽器在非 HTTPS 環境下傳送敏感資訊
        headers["Referrer-Policy"] = "strict-origin-when-cross-origin";

        // 限制瀏覽器功能（禁用不需要的 Web API）
        headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=(), payment=()";

        // Content Security Policy
        headers["Content-Security-Policy"] = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'";

        // 快取控制 — API 回應預設不快取
        if (context.Request.Path.StartsWithSegments("/api"))
        {
            headers["Cache-Control"] = "no-store, no-cache, must-revalidate";
            headers["Pragma"] = "no-cache";
        }

        await _next(context);
    }
}
