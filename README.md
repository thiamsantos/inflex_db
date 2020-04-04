# InflexDB

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `inflex_db` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:inflex_db, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/inflex_db](https://hexdocs.pm/inflex_db).

## TODO

client = %InflexDB.Client{url: "http://localhost:8086", username: "admin", jwt_secret: "super-secret", auth_method: "jwt", jwt_ttl: 60}

InflexDB.write_point(client, name, data, opts)
InflexDB.write_points(client, data, opts)
inflexDB.query(client, query, opts)
InflexDB.create_database(client, name)
InflexDB.delete_databade(client, name)
InflexDB.list_databases(client)
InflexDB.create_database_user(client, database, username, password, options)
InflexDB.update_user_password(client, username, password)
InflexDB.grant_user_privileges(client, username, database, permission)
InflexDB.revoke_user_privileges(client, username, database, permission)
InflexDB.delete_user(client, username)
InflexDB.list_users(client)
InflexDB.create_cluster_admin(client, username, password)
InflexDB.list_cluster_admins(client)
InflexDB.revoke_cluster_admin_privileges(client, username)
InflexDB.list_continuous_queries(client, database)
InflexDB.create_continuous_query(client, name, database, query, opts)
InflexDB.delete_continuous_query(client, name, database)
InflexDB.list_retention_policies(client, database)
create_retention_police

Json library as option

https://github.com/influxdata/influxdb-client-ruby/blob/master/README.md
https://v2.docs.influxdata.com/v2.0/reference/api/client-libraries/
