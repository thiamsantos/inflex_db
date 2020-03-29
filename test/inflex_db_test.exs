defmodule InflexDBTest do
  use ExUnit.Case, async: true
  import Mox
  import Plug.Conn

  alias InflexDB.{Client, CurrentTimeMock}

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
        response = Jason.encode!(%{
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
        response = Jason.encode!(%{
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
