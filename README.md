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

client = %Inflex.Client{url: ""}

Inflex.write_point(client, name, data, opts)
Inflex.write_points(client, data, opts)
inflex.query(client, query, opts)
Inflex.create_database(client, name)
Inflex.delete_databade(client, name)
Inflex.list_databases(client)
Inflex.create_database_user(client, database, username, password, options)
Inflex.update_user_password(client, username, password)
Inflex.grant_user_privileges(client, username, database, permission)
Inflex.revoke_user_privileges(client, username, database, permission)
Inflex.delete_user(client, username)
Inflex.list_users(client)
Inflex.create_cluster_admin(client, username, password)
Inflex.list_cluster_admins(client)
Inflex.revoke_cluster_admin_privileges(client, username)
Inflex.list_continuous_queries(client, database)
Inflex.create_continuous_query(client, name, database, query, opts)
Inflex.delete_continuous_query(client, name, database)
Inflex.list_retention_policies(client, database)
create_retention_police

Json library as option

https://github.com/influxdata/influxdb-client-ruby/blob/master/README.md
https://v2.docs.influxdata.com/v2.0/reference/api/client-libraries/

Bypass
