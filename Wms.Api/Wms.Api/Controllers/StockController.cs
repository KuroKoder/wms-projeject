using Microsoft.AspNetCore.Mvc;
using Wms.Api.Dtos;
using Wms.Api.Services;

namespace Wms.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class StockController : ControllerBase
{
    private readonly StockService _service;

    public StockController(StockService service) => _service = service;

    [HttpPost("in")]
    public async Task<IActionResult> StockIn([FromBody] StockInRequest req, CancellationToken ct)
    {
        try
        {
            var (txnId, txnNo) = await _service.StockInAsync(req, ct);
            return Ok(new { txnId, txnNo });
        }
        catch (SqlExceptionLike ex) // placeholder (lihat Program.cs mapping)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("out")]
    public async Task<IActionResult> StockOut([FromBody] StockOutRequest req, CancellationToken ct)
    {
        try
        {
            var (txnId, txnNo) = await _service.StockOutAsync(req, ct);
            return Ok(new { txnId, txnNo });
        }
        catch (SqlExceptionLike ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}

// Trick sederhana biar compile tanpa nambah reference langsung di controller.
// Nanti kita rapihin di Program.cs dengan handler exception global.
public class SqlExceptionLike : Exception
{
    public SqlExceptionLike(string message) : base(message) { }
}
