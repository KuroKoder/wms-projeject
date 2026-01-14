using Microsoft.AspNetCore.Mvc;
using Wms.Api.Domain.Entities;
using Wms.Api.Infrastructure.Repositories;

namespace Wms.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class ItemsController : ControllerBase
{
    private readonly IItemRepository _repo;

    public ItemsController(IItemRepository repo) => _repo = repo;

    [HttpGet]
    public async Task<IActionResult> GetAll(CancellationToken ct)
        => Ok(await _repo.GetAllAsync(ct));

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById([FromRoute] int id, CancellationToken ct)
    {
        var item = await _repo.GetByIdAsync(id, ct);
        return item is null ? NotFound() : Ok(item);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Item item, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(item.Sku)) return BadRequest(new { error = "sku required" });
        if (string.IsNullOrWhiteSpace(item.ItemName)) return BadRequest(new { error = "itemName required" });

        var newId = await _repo.CreateAsync(item, ct);
        return CreatedAtAction(nameof(GetById), new { id = newId }, new { itemId = newId });
    }
}
