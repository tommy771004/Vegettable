using Microsoft.AspNetCore.Mvc;
using VegettableApi.Data;
using VegettableApi.Data.Entities;
using VegettableApi.Models;

namespace VegettableApi.Controllers;

/// <summary>
/// 使用者回饋 API
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class FeedbackController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly ILogger<FeedbackController> _logger;

    public FeedbackController(AppDbContext db, ILogger<FeedbackController> logger)
    {
        _db = db;
        _logger = logger;
    }

    /// <summary>
    /// 提交使用者回饋
    /// </summary>
    /// <remarks>
    /// 接受使用者的錯誤回報、功能建議或其他回饋，儲存至資料庫。
    /// </remarks>
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<FeedbackResultDto>), 201)]
    [ProducesResponseType(typeof(ApiResponse<object>), 400)]
    public async Task<IActionResult> SubmitFeedback([FromBody] SubmitFeedbackRequest request)
    {
        if (!ModelState.IsValid)
        {
            var errors = ModelState.Values
                .SelectMany(v => v.Errors)
                .Select(e => e.ErrorMessage)
                .FirstOrDefault() ?? "請求格式無效";
            return BadRequest(ApiResponse<object>.Fail(errors));
        }

        var submission = new FeedbackSubmission
        {
            FeedbackType = request.FeedbackType,
            Content = request.Content.Trim(),
            DeviceToken = string.IsNullOrWhiteSpace(request.DeviceToken) ? null : request.DeviceToken,
            Platform = string.IsNullOrWhiteSpace(request.Platform) ? null : request.Platform,
            AppVersion = string.IsNullOrWhiteSpace(request.AppVersion) ? null : request.AppVersion,
        };

        _db.FeedbackSubmissions.Add(submission);
        await _db.SaveChangesAsync();

        _logger.LogInformation(
            "收到回饋 #{Id} 類型={Type} 平台={Platform} 版本={Version}",
            submission.Id, submission.FeedbackType, submission.Platform, submission.AppVersion);

        var result = new FeedbackResultDto
        {
            Id = submission.Id,
            Message = "感謝您的回饋，我們已收到並將盡快處理！",
            CreatedAt = submission.CreatedAt,
        };

        return Created($"/api/feedback/{submission.Id}", ApiResponse<FeedbackResultDto>.Ok(result));
    }
}
