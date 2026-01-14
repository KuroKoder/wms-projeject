# wms-projeject
```
wms-project
├─ README.md
└─ Wms.Api
   ├─ Wms.Api
   │  ├─ appsettings.Development.json
   │  ├─ appsettings.json
   │  ├─ Controllers
   │  │  ├─ ItemsController.cs
   │  │  └─ StockController.cs
   │  ├─ Domain
   │  │  ├─ Entities
   │  │  │  ├─ InventoryOnHand.cs
   │  │  │  ├─ Item.cs
   │  │  │  └─ StockTransaction.cs
   │  │  └─ Enums
   │  │     └─ TransactionType.cs
   │  ├─ Dtos
   │  │  ├─ StockInRequest.cs
   │  │  └─ StockOutRequest.cs
   │  ├─ Infrastructure
   │  │  ├─ Db
   │  │  │  └─ SqlConnectionFactory.cs
   │  │  └─ Repositories
   │  │     ├─ IItemRepository.cs
   │  │     ├─ IStockRepository.cs
   │  │     ├─ ItemRepository.cs
   │  │     └─ StockRepository.cs
   │  ├─ Program.cs
   │  ├─ Properties
   │  │  └─ launchSettings.json
   │  ├─ Services
   │  │  └─ StockService.cs
   │  ├─ Wms.Api.csproj
   │  └─ Wms.Api.http
   └─ Wms.sln

```