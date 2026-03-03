using System.Net;
using System.Text.Json;
using VegettableApi.Models;

namespace VegettableApi.Middleware;

/// <summary>
/// 全域例外處理中介層
/// </summary>
public class ExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionMiddleware> _logger;

    public ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "外部 API 請求失敗");
            await WriteErrorResponseAsync(context, HttpStatusCode.BadGateway,
                "農業部資料服務暫時無法連線，請稍後再試");
        }
        catch (TaskCanceledException ex)
        {
            _logger.LogWarning(ex, "請求逾時");
            await WriteErrorResponseAsync(context, HttpStatusCode.GatewayTimeout,
                "農業部資料服務回應逾時，請稍後再試");
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "JSON 解析失敗");
            await WriteErrorResponseAsync(context, HttpStatusCode.BadGateway,
                "農業部資料格式異常，請稍後再試");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "未預期的錯誤");
            await WriteErrorResponseAsync(context, HttpStatusCode.InternalServerError,
                "伺服器內部錯誤，請稍後再試");
        }
    }

    private static async Task WriteErrorResponseAsync(
        HttpContext context, HttpStatusCode statusCode, string message)
    {
        context.Response.ContentType = "application/json; charset=utf-8";
        context.Response.StatusCode = (int)statusCode;

        var response = ApiResponse<object>.Fail(message);
        var json = JsonSerializer.Serialize(response, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        });
        await context.Response.WriteAsync(json);
    }
}
