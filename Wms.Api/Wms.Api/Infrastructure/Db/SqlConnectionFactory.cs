using System.Data;
using Microsoft.Data.SqlClient;

namespace Wms.Api.Infrastructure.Db;

public sealed class SqlConnectionFactory
{
    private readonly string _connectionString;

    public SqlConnectionFactory(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Missing ConnectionStrings:DefaultConnection in appsettings.json");
    }

    public IDbConnection CreateConnection() => new SqlConnection(_connectionString);
}
