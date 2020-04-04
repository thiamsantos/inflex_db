# InflexDB

Elixir client for [InfluxDB](https://www.influxdata.com/products/influxdb-overview/)

## Installation

The package can be installed
by adding `inflex_db` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:inflex_db, "~> 0.1.0"},
    {:jason, "~> 1.1"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/inflex_db](https://hexdocs.pm/inflex_db).

## Usage

```elixir
client = %InflexDB.Client{
  url: "http://localhost:8086",
  username: "admin",
  password: "admin",
  auth_method: "basic"
}

points = [
  %InflexDB.Point{
    measurement: "weather",
    tag_set: %{location: "us-midwest"},
    field_set: %{temperature: 82}
  },
  %InflexDB.Point{
    measurement: "weather",
    tag_set: %{location: "us-midwest"},
    field_set: %{temperature: 76}
  }
]

InflexDB.write_points(client, "mydb", points)
# :ok
```

Checkout the [docs](https://hexdocs.pm/inflex_db) for all the operations supported and more examples.

## License

[Apache License, Version 2.0](LICENSE) © [Thiago Santos](https://github.com/thiamsantos)
