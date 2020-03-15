defmodule InflexDB.LineProtocolTest do
  use ExUnit.Case, async: true

  alias InflexDB.{LineProtocol, Point}

  describe "encode/1" do
    test "works" do
      point = %Point{
        measurement: "weather",
        tag_set: %{location: "us-midwest"},
        field_set: %{temperature: 82},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])
      expected = "weather,location=us-midwest temperature=82i 1465839830100400200"

      assert actual == expected
    end

    test "float" do
      point = %Point{
        measurement: "weather",
        tag_set: %{location: "us-midwest"},
        field_set: %{temperature: 85.7},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])
      expected = "weather,location=us-midwest temperature=85.7 1465839830100400200"

      assert actual == expected
    end

    test "true" do
      point = %Point{
        measurement: "weather",
        tag_set: %{location: "us-midwest"},
        field_set: %{temperature: true},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])
      expected = "weather,location=us-midwest temperature=true 1465839830100400200"

      assert actual == expected
    end

    test "false" do
      point = %Point{
        measurement: "weather",
        tag_set: %{location: "us-midwest"},
        field_set: %{temperature: false},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])
      expected = "weather,location=us-midwest temperature=false 1465839830100400200"

      assert actual == expected
    end

    test "string" do
      point = %Point{
        measurement: "weather",
        tag_set: %{location: "us-midwest"},
        field_set: %{temperature: "27 c"},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])
      expected = ~S(weather,location=us-midwest temperature="27 c" 1465839830100400200)

      assert actual == expected
    end

    test "multiple" do
      point = %Point{
        measurement: "weather",
        tag_set: %{another: 27, location: "us-midwest", doctor: "john"},
        field_set: %{bring: "back", temperature: 82, another: false},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])

      expected =
        ~S(weather,another=27,doctor=john,location=us-midwest another=false,bring="back",temperature=82i 1465839830100400200)

      assert actual == expected
    end

    test "field values escape" do
      point = %Point{
        measurement: "weather",
        tag_set: %{location: "us-midwest"},
        field_set: %{temperature: ~S(27 "c)},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])
      expected = ~S(weather,location=us-midwest temperature="27 \"c" 1465839830100400200)

      assert actual == expected
    end

    test "measurement with space" do
      point = %Point{
        measurement: "wea ther",
        tag_set: %{location: "us-midwest"},
        field_set: %{temperature: 82},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])
      expected = ~S(wea\ ther,location=us-midwest temperature=82i 1465839830100400200)

      assert actual == expected
    end

    test "measurement with comma" do
      point = %Point{
        measurement: "wea,ther",
        tag_set: %{location: "us-midwest"},
        field_set: %{temperature: 82},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])
      expected = ~S(wea\,ther,location=us-midwest temperature=82i 1465839830100400200)

      assert actual == expected
    end

    test "tag keys with commas" do
      point = %Point{
        measurement: "weather",
        tag_set: %{"nothing,location" => "us-midwest"},
        field_set: %{temperature: 82},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])
      expected = ~S(weather,nothing\,location=us-midwest temperature=82i 1465839830100400200)

      assert actual == expected
    end

    test "tag keys with equal signs" do
      point = %Point{
        measurement: "weather",
        tag_set: %{"nothing=location" => "us-midwest"},
        field_set: %{temperature: 82},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])
      expected = ~S(weather,nothing\=location=us-midwest temperature=82i 1465839830100400200)

      assert actual == expected
    end

    test "tag keys with spaces" do
      point = %Point{
        measurement: "weather",
        tag_set: %{"nothing location" => "us-midwest"},
        field_set: %{temperature: 82},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])
      expected = ~S(weather,nothing\ location=us-midwest temperature=82i 1465839830100400200)

      assert actual == expected
    end

    test "tag values with commas" do
      point = %Point{
        measurement: "weather",
        tag_set: %{location: "us,midwest"},
        field_set: %{temperature: 82},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])
      expected = ~S(weather,location=us\,midwest temperature=82i 1465839830100400200)

      assert actual == expected
    end

    test "tag values with equal signs" do
      point = %Point{
        measurement: "weather",
        tag_set: %{location: "us=midwest"},
        field_set: %{temperature: 82},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])
      expected = ~S(weather,location=us\=midwest temperature=82i 1465839830100400200)

      assert actual == expected
    end

    test "tag values with spaces" do
      point = %Point{
        measurement: "weather",
        tag_set: %{location: "us midwest"},
        field_set: %{temperature: 82},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])
      expected = ~S(weather,location=us\ midwest temperature=82i 1465839830100400200)

      assert actual == expected
    end

    test "field keys with commas" do
      point = %Point{
        measurement: "weather",
        tag_set: %{location: "us-midwest"},
        field_set: %{"foo,temperature" => 82},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])
      expected = ~S(weather,location=us-midwest foo\,temperature=82i 1465839830100400200)

      assert actual == expected
    end

    test "field keys with equal signs" do
      point = %Point{
        measurement: "weather",
        tag_set: %{location: "us-midwest"},
        field_set: %{"foo=temperature" => 82},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])
      expected = ~S(weather,location=us-midwest foo\=temperature=82i 1465839830100400200)

      assert actual == expected
    end

    test "field keys with spaces" do
      point = %Point{
        measurement: "weather",
        tag_set: %{location: "us-midwest"},
        field_set: %{"foo temperature" => 82},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])
      expected = ~S(weather,location=us-midwest foo\ temperature=82i 1465839830100400200)

      assert actual == expected
    end

    test "no tags" do
      point = %Point{
        measurement: "weather",
        field_set: %{temperature: 82},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])
      expected = "weather temperature=82i 1465839830100400200"

      assert actual == expected
    end

    test "empty tags" do
      point = %Point{
        measurement: "weather",
        tag_set: %{},
        field_set: %{temperature: 82},
        timestamp: 1_465_839_830_100_400_200
      }

      actual = LineProtocol.encode([point])
      expected = "weather temperature=82i 1465839830100400200"

      assert actual == expected
    end

    test "no timestamp" do
      point = %Point{
        measurement: "weather",
        tag_set: %{location: "us-midwest"},
        field_set: %{temperature: 82}
      }

      actual = LineProtocol.encode([point])
      expected = "weather,location=us-midwest temperature=82i"

      assert actual == expected
    end

    test "multiple points" do
      point1 = %Point{
        measurement: "weather1",
        tag_set: %{location: "us-midwest"},
        field_set: %{temperature: 82}
      }

      point2 = %Point{
        measurement: "weather2",
        tag_set: %{location: "us-midwest"},
        field_set: %{temperature: 82}
      }

      actual = LineProtocol.encode([point1, point2])

      expected =
        "weather1,location=us-midwest temperature=82i\nweather2,location=us-midwest temperature=82i"

      assert actual == expected
    end

    test "mixed atom string keys" do
      point = %Point{
        measurement: "weather1",
        tag_set: %{:location => "us-midwest", "nothing location" => "us-midwest"},
        field_set: %{temperature: 82}
      }

      actual = LineProtocol.encode([point])

      expected = ~S(weather1,location=us-midwest,nothing\ location=us-midwest temperature=82i)

      assert actual == expected
    end
  end
end
