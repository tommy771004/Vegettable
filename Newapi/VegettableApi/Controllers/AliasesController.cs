using Microsoft.AspNetCore.Mvc;
using VegettableApi.Models;
using VegettableApi.Services;

namespace VegettableApi.Controllers;

/// <summary>
/// 品項別名查詢 API
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class AliasesController : ControllerBase
{
    /// <summary>
    /// 由別名反查正式名稱
    /// </summary>
    /// <param name="name">品項名稱或別名</param>
    [HttpGet("lookup")]
    [ProducesResponseType(typeof(ApiResponse<AliasLookupResult>), 200)]
    public IActionResult LookupAlias([FromQuery] string name)
    {
        if (string.IsNullOrWhiteSpace(name))
            return BadRequest(ApiResponse<object>.Fail("請提供品項名稱"));

        var official = CropAliases.FindOfficialName(name.Trim());
        var allNames = official != null
            ? CropAliases.GetAllNames(official)
            : new List<string> { name.Trim() };

        return Ok(ApiResponse<AliasLookupResult>.Ok(new AliasLookupResult
        {
            Input = name.Trim(),
            OfficialName = official,
            AllNames = allNames,
        }));
    }
}

public class AliasLookupResult
{
    public string Input { get; set; } = string.Empty;
    public string? OfficialName { get; set; }
    public List<string> AllNames { get; set; } = new();
}
