defmodule InflexDBTest do
  use ExUnit.Case, async: true
  import Mox
  import Plug.Conn
  alias InflexDB.{Client, CurrentTimeMock, Point, HTTPResponse}

  setup do
    verify_on_exit!()
    {:ok, bypass: Bypass.open()}
  end

  describe "ping/1" do
    test "success", %{bypass: bypass} do
      client = %Client{
        url: "http://localhost:#{bypass.port}/",
        username: "admin",
        password: "password"
      }

      Bypass.expect_once(bypass, "GET", "/ping", fn conn ->
        resp(conn, 204, "")
      end)

      assert InflexDB.ping(client) == :ok
    end

    test "influx db out", %{bypass: bypass} do
      client = %Client{
        url: "http://localhost:#{bypass.port}/",
        username: "admin",
        password: "password"
      }

      Bypass.down(bypass)

      assert InflexDB.ping(client) == {:error, :econnrefused}
    end
  end

  describe "create_database/2" do
    test "success", %{bypass: bypass} do
      client = %Client{
        url: "http://localhost:#{bypass.port}/",
        username: "admin",
        password: "password"
      }

      Bypass.expect_once(bypass, "POST", "/query", fn conn ->
        response = Jason.encode!(%{"results" => [%{"statement_id" => 0}]})

        assert get_req_header(conn, "content-type") == ["application/x-www-form-urlencoded"]

        {:ok, body, _conn} = read_body(conn)
        assert URI.decode_query(body) == %{"q" => ~s(CREATE DATABASE "mydb";)}

        conn
        |> put_resp_header("content-type", "application/json")
        |> resp(200, response)
      end)

      assert InflexDB.create_database(client, "mydb") == :ok
    end
  end

  describe "delete_database/2" do
    test "success", %{bypass: bypass} do
      client = %Client{
        url: "http://localhost:#{bypass.port}/",
        username: "admin",
        password: "password"
      }

      Bypass.expect_once(bypass, "POST", "/query", fn conn ->
        response = Jason.encode!(%{"results" => [%{"statement_id" => 0}]})

        assert get_req_header(conn, "content-type") == ["application/x-www-form-urlencoded"]

        {:ok, body, _conn} = read_body(conn)
        assert URI.decode_query(body) == %{"q" => ~s(DROP DATABASE "mydb";)}

        conn
        |> put_resp_header("content-type", "application/json")
        |> resp(200, response)
      end)

      assert InflexDB.delete_database(client, "mydb") == :ok
    end
  end

  describe "list_databases/1" do
    test "no databases", %{bypass: bypass} do
      client = %Client{
        url: "http://localhost:#{bypass.port}/",
        username: "admin",
        password: "password"
      }

      Bypass.expect_once(bypass, "POST", "/query", fn conn ->
        response =
          Jason.encode!(%{
            "results" => [
              %{
                "series" => [%{"columns" => ["name"], "name" => "databases"}],
                "statement_id" => 0
              }
            ]
          })

        assert get_req_header(conn, "content-type") == ["application/x-www-form-urlencoded"]

        {:ok, body, _conn} = read_body(conn)
        assert URI.decode_query(body) == %{"q" => "SHOW DATABASES;"}

        conn
        |> put_resp_header("content-type", "application/json")
        |> resp(200, response)
      end)

      assert InflexDB.list_databases(client) == {:ok, []}
    end

    test "success", %{bypass: bypass} do
      client = %Client{
        url: "http://localhost:#{bypass.port}/",
        username: "admin",
        password: "password"
      }

      Bypass.expect_once(bypass, "POST", "/query", fn conn ->
        response =
          Jason.encode!(%{
            "results" => [
              %{
                "series" => [
                  %{
                    "columns" => ["name"],
                    "name" => "databases",
                    "values" => [["_internal"], ["mydb"]]
                  }
                ],
                "statement_id" => 0
              }
            ]
          })

        assert get_req_header(conn, "content-type") == ["application/x-www-form-urlencoded"]

        {:ok, body, _conn} = read_body(conn)
        assert URI.decode_query(body) == %{"q" => "SHOW DATABASES;"}

        conn
        |> put_resp_header("content-type", "application/json")
        |> resp(200, response)
      end)

      assert InflexDB.list_databases(client) == {:ok, ["_internal", "mydb"]}
    end
  end

  describe "write_points/3" do
    test "success", %{bypass: bypass} do
      client = %Client{
        url: "http://localhost:#{bypass.port}/",
        username: "admin",
        password: "password"
      }

      Bypass.expect_once(bypass, "POST", "/write", fn conn ->
        assert conn.query_string == "db=mydb"
        assert get_req_header(conn, "content-type") == ["text/plain"]

        {:ok, body, _conn} = read_body(conn)

        assert body ==
                 "weather,location=us-midwest temperature=82i\n" <>
                   "weather,location=us-midwest temperature=76i"

        conn
        |> resp(204, "")
      end)

      points = [
        %Point{
          measurement: "weather",
          tag_set: %{location: "us-midwest"},
          field_set: %{temperature: 82}
        },
        %Point{
          measurement: "weather",
          tag_set: %{location: "us-midwest"},
          field_set: %{temperature: 76}
        }
      ]

      assert InflexDB.write_points(client, "mydb", points) == :ok
    end

    test "database not found", %{bypass: bypass} do
      client = %Client{
        url: "http://localhost:#{bypass.port}/",
        username: "admin",
        password: "password"
      }

      Bypass.expect_once(bypass, "POST", "/write", fn conn ->
        response = Jason.encode!(%{"error" => "database not found: \"mydb\""})

        conn
        |> put_resp_header("content-type", "application/json")
        |> resp(404, response)
      end)

      points = [
        %Point{
          measurement: "weather",
          tag_set: %{location: "us-midwest"},
          field_set: %{temperature: 82}
        },
        %Point{
          measurement: "weather",
          tag_set: %{location: "us-midwest"},
          field_set: %{temperature: 76}
        }
      ]

      assert {:error,
              %HTTPResponse{
                body: %{"error" => "database not found: \"mydb\""},
                status: 404
              }} = InflexDB.write_points(client, "mydb", points)
    end
  end

  describe "write_point/3" do
    test "success", %{bypass: bypass} do
      client = %Client{
        url: "http://localhost:#{bypass.port}/",
        username: "admin",
        password: "password"
      }

      Bypass.expect_once(bypass, "POST", "/write", fn conn ->
        assert conn.query_string == "db=mydb"
        assert get_req_header(conn, "content-type") == ["text/plain"]

        {:ok, body, _conn} = read_body(conn)

        assert body ==
                 "weather,location=us-midwest temperature=82i"

        conn
        |> resp(204, "")
      end)

      point = %Point{
        measurement: "weather",
        tag_set: %{location: "us-midwest"},
        field_set: %{temperature: 82}
      }

      assert InflexDB.write_point(client, "mydb", point) == :ok
    end

    test "database not found", %{bypass: bypass} do
      client = %Client{
        url: "http://localhost:#{bypass.port}/",
        username: "admin",
        password: "password"
      }

      Bypass.expect_once(bypass, "POST", "/write", fn conn ->
        response = Jason.encode!(%{"error" => "database not found: \"mydb\""})

        conn
        |> put_resp_header("content-type", "application/json")
        |> resp(404, response)
      end)

      point = %Point{
        measurement: "weather",
        tag_set: %{location: "us-midwest"},
        field_set: %{temperature: 82}
      }

      assert {:error,
              %HTTPResponse{
                body: %{"error" => "database not found: \"mydb\""},
                status: 404
              }} = InflexDB.write_point(client, "mydb", point)
    end
  end

  describe "query/3" do
    test "success", %{bypass: bypass} do
      client = %Client{
        url: "http://localhost:#{bypass.port}/",
        username: "admin",
        password: "password"
      }

      Bypass.expect_once(bypass, "GET", "/query", fn conn ->
        assert URI.decode_query(conn.query_string) == %{
                 "db" => "mydb",
                 "q" => "SELECT * FROM weather"
               }

        response =
          Jason.encode!(%{
            "results" => [
              %{
                "series" => [
                  %{
                    "columns" => ["time", "location", "season", "temperature"],
                    "name" => "weather",
                    "values" => [
                      ["2020-03-29T20:34:46.725338219Z", "us-midwest", "summer", 82],
                      ["2020-03-29T20:40:46.790074049Z", "us-east", "summer", 879]
                    ]
                  }
                ],
                "statement_id" => 0
              }
            ]
          })

        conn
        |> put_resp_header("content-type", "application/json")
        |> resp(200, response)
      end)

      assert InflexDB.query(client, "mydb", "SELECT * FROM weather") ==
               {:ok,
                [
                  %{
                    name: "weather",
                    statement_id: 0,
                    tags: nil,
                    values: [
                      %{
                        "location" => "us-midwest",
                        "season" => "summer",
                        "temperature" => 82,
                        "time" => "2020-03-29T20:34:46.725338219Z"
                      },
                      %{
                        "season" => "summer",
                        "location" => "us-east",
                        "temperature" => 879,
                        "time" => "2020-03-29T20:40:46.790074049Z"
                      }
                    ]
                  }
                ]}
    end

    test "query with group by ", %{bypass: bypass} do
      client = %Client{
        url: "http://localhost:#{bypass.port}/",
        username: "admin",
        password: "password"
      }

      Bypass.expect_once(bypass, "GET", "/query", fn conn ->
        assert URI.decode_query(conn.query_string) == %{
                 "db" => "mydb",
                 "q" => "SELECT * FROM weather GROUP BY location"
               }

        response =
          Jason.encode!(%{
            "results" => [
              %{
                "series" => [
                  %{
                    "columns" => ["time", "season", "temperature"],
                    "name" => "weather",
                    "tags" => %{"location" => "us-east"},
                    "values" => [
                      ["2020-03-29T20:40:46.790074049Z", "summer", 879],
                      ["2020-03-29T20:40:46.790074049Z", "winter", 8096]
                    ]
                  },
                  %{
                    "columns" => ["time", "season", "temperature"],
                    "name" => "weather",
                    "tags" => %{"location" => "us-midwest"},
                    "values" => [
                      ["2020-03-29T20:34:46.725338219Z", "summer", 82],
                      ["2020-03-29T20:40:46.790074049Z", "winter", 9577]
                    ]
                  }
                ],
                "statement_id" => 0
              }
            ]
          })

        conn
        |> put_resp_header("content-type", "application/json")
        |> resp(200, response)
      end)

      assert InflexDB.query(client, "mydb", "SELECT * FROM weather GROUP BY location") ==
               {:ok,
                [
                  %{
                    name: "weather",
                    statement_id: 0,
                    tags: %{"location" => "us-east"},
                    values: [
                      %{
                        "season" => "summer",
                        "temperature" => 879,
                        "time" => "2020-03-29T20:40:46.790074049Z"
                      },
                      %{
                        "season" => "winter",
                        "temperature" => 8096,
                        "time" => "2020-03-29T20:40:46.790074049Z"
                      }
                    ]
                  },
                  %{
                    name: "weather",
                    statement_id: 0,
                    tags: %{"location" => "us-midwest"},
                    values: [
                      %{
                        "season" => "summer",
                        "temperature" => 82,
                        "time" => "2020-03-29T20:34:46.725338219Z"
                      },
                      %{
                        "season" => "winter",
                        "temperature" => 9577,
                        "time" => "2020-03-29T20:40:46.790074049Z"
                      }
                    ]
                  }
                ]}
    end

    test "multiple queries", %{bypass: bypass} do
      client = %Client{
        url: "http://localhost:#{bypass.port}/",
        username: "admin",
        password: "password"
      }

      Bypass.expect_once(bypass, "GET", "/query", fn conn ->
        assert URI.decode_query(conn.query_string) == %{
                 "db" => "mydb",
                 "q" =>
                   "SELECT * FROM weather group by location; SELECT * from weather2 group by season"
               }

        response =
          Jason.encode!(%{
            "results" => [
              %{
                "series" => [
                  %{
                    "columns" => ["time", "season", "temperature"],
                    "name" => "weather",
                    "tags" => %{"location" => "us-east"},
                    "values" => [
                      ["2020-03-29T20:40:46.790074049Z", "summer", 879],
                      ["2020-03-29T20:40:46.790074049Z", "winter", 8096]
                    ]
                  },
                  %{
                    "columns" => ["time", "season", "temperature"],
                    "name" => "weather",
                    "tags" => %{"location" => "us-midwest"},
                    "values" => [
                      ["2020-03-29T20:34:46.725338219Z", "summer", 82],
                      ["2020-03-29T20:35:15.531091771Z", "summer", 82]
                    ]
                  }
                ],
                "statement_id" => 0
              },
              %{
                "series" => [
                  %{
                    "columns" => ["time", "location", "temperature"],
                    "name" => "weather2",
                    "tags" => %{"season" => "summer"},
                    "values" => [
                      ["2020-03-29T20:59:41.755035346Z", "us-east", 842],
                      ["2020-03-29T20:59:41.755035346Z", "us-midwest", 2342]
                    ]
                  },
                  %{
                    "columns" => ["time", "location", "temperature"],
                    "name" => "weather2",
                    "tags" => %{"season" => "winter"},
                    "values" => [
                      ["2020-03-29T20:59:41.755035346Z", "us-east", 7554],
                      ["2020-03-29T20:59:41.755035346Z", "us-midwest", 5473]
                    ]
                  }
                ],
                "statement_id" => 1
              }
            ]
          })

        conn
        |> put_resp_header("content-type", "application/json")
        |> resp(200, response)
      end)

      assert InflexDB.query(
               client,
               "mydb",
               "SELECT * FROM weather group by location; SELECT * from weather2 group by season"
             ) ==
               {:ok,
                [
                  %{
                    name: "weather",
                    statement_id: 0,
                    tags: %{"location" => "us-east"},
                    values: [
                      %{
                        "season" => "summer",
                        "temperature" => 879,
                        "time" => "2020-03-29T20:40:46.790074049Z"
                      },
                      %{
                        "season" => "winter",
                        "temperature" => 8096,
                        "time" => "2020-03-29T20:40:46.790074049Z"
                      }
                    ]
                  },
                  %{
                    name: "weather",
                    statement_id: 0,
                    tags: %{"location" => "us-midwest"},
                    values: [
                      %{
                        "season" => "summer",
                        "temperature" => 82,
                        "time" => "2020-03-29T20:34:46.725338219Z"
                      },
                      %{
                        "season" => "summer",
                        "temperature" => 82,
                        "time" => "2020-03-29T20:35:15.531091771Z"
                      }
                    ]
                  },
                  %{
                    name: "weather2",
                    statement_id: 1,
                    tags: %{"season" => "summer"},
                    values: [
                      %{
                        "location" => "us-east",
                        "temperature" => 842,
                        "time" => "2020-03-29T20:59:41.755035346Z"
                      },
                      %{
                        "location" => "us-midwest",
                        "temperature" => 2342,
                        "time" => "2020-03-29T20:59:41.755035346Z"
                      }
                    ]
                  },
                  %{
                    name: "weather2",
                    statement_id: 1,
                    tags: %{"season" => "winter"},
                    values: [
                      %{
                        "location" => "us-east",
                        "temperature" => 7554,
                        "time" => "2020-03-29T20:59:41.755035346Z"
                      },
                      %{
                        "location" => "us-midwest",
                        "temperature" => 5473,
                        "time" => "2020-03-29T20:59:41.755035346Z"
                      }
                    ]
                  }
                ]}
    end
  end

  describe "authentication" do
    test "supports basic authentication", %{bypass: bypass} do
      client = %Client{
        url: "http://localhost:#{bypass.port}/",
        username: "admin",
        password: "password",
        auth_method: "basic"
      }

      Bypass.expect_once(bypass, "POST", "/query", fn conn ->
        assert get_req_header(conn, "authorization") == [
                 "Basic " <> Base.encode64("admin:password")
               ]

        assert fetch_query_params(conn).query_params == %{}

        response =
          Jason.encode!(%{
            "results" => [
              %{
                "series" => [
                  %{
                    "columns" => ["name"],
                    "name" => "databases",
                    "values" => [["_internal"], ["mydb"]]
                  }
                ],
                "statement_id" => 0
              }
            ]
          })

        conn
        |> put_resp_header("content-type", "application/json")
        |> resp(200, response)
      end)

      assert InflexDB.list_databases(client) == {:ok, ["_internal", "mydb"]}
    end

    test "supports params authentication", %{bypass: bypass} do
      client = %Client{
        url: "http://localhost:#{bypass.port}/",
        username: "admin",
        password: "password",
        auth_method: "params"
      }

      Bypass.expect_once(bypass, "POST", "/query", fn conn ->
        assert get_req_header(conn, "authorization") == []
        assert fetch_query_params(conn).query_params == %{"u" => "admin", "p" => "password"}

        response =
          Jason.encode!(%{
            "results" => [
              %{
                "series" => [
                  %{
                    "columns" => ["name"],
                    "name" => "databases",
                    "values" => [["_internal"], ["mydb"]]
                  }
                ],
                "statement_id" => 0
              }
            ]
          })

        conn
        |> put_resp_header("content-type", "application/json")
        |> resp(200, response)
      end)

      assert InflexDB.list_databases(client) == {:ok, ["_internal", "mydb"]}
    end

    test "supports none authentication", %{bypass: bypass} do
      client = %Client{url: "http://localhost:#{bypass.port}/", auth_method: "none"}

      Bypass.expect_once(bypass, "POST", "/query", fn conn ->
        assert get_req_header(conn, "authorization") == []
        assert fetch_query_params(conn).query_params == %{}

        response =
          Jason.encode!(%{
            "results" => [
              %{
                "series" => [
                  %{
                    "columns" => ["name"],
                    "name" => "databases",
                    "values" => [["_internal"], ["mydb"]]
                  }
                ],
                "statement_id" => 0
              }
            ]
          })

        conn
        |> put_resp_header("content-type", "application/json")
        |> resp(200, response)
      end)

      assert InflexDB.list_databases(client) == {:ok, ["_internal", "mydb"]}
    end

    test "supports jwt authentication", %{bypass: bypass} do
      client = %Client{
        url: "http://localhost:#{bypass.port}/",
        auth_method: "jwt",
        username: "admin",
        jwt_secret: "super-secret",
        jwt_ttl: 60
      }

      epoch_now = DateTime.to_unix(DateTime.utc_now())

      expect(CurrentTimeMock, :epoch_now, fn -> epoch_now end)

      Bypass.expect_once(bypass, "POST", "/query", fn conn ->
        assert fetch_query_params(conn).query_params == %{}
        assert ["Bearer " <> jwt_token] = get_req_header(conn, "authorization")

        assert {true, claims, _} =
                 "super-secret"
                 |> JOSE.JWK.from_oct()
                 |> JOSE.JWT.verify_strict(["HS256"], jwt_token)

        assert claims.fields == %{"exp" => epoch_now + 60, "username" => "admin"}

        response =
          Jason.encode!(%{
            "results" => [
              %{
                "series" => [
                  %{
                    "columns" => ["name"],
                    "name" => "databases",
                    "values" => [["_internal"], ["mydb"]]
                  }
                ],
                "statement_id" => 0
              }
            ]
          })

        conn
        |> put_resp_header("content-type", "application/json")
        |> resp(200, response)
      end)

      assert InflexDB.list_databases(client) == {:ok, ["_internal", "mydb"]}
    end
  end
end
