# --------------------
# Tideland Elixir Application Support - Top - Tests
# Copyright (C) 2014-2015 Frank Mueller / Tideland / Oldenburg / Germany
# --------------------

defmodule EXAS.TopTest do
  use ExUnit.Case, async: true
  require EXAS.Top

  test "one simple measuring point" do
    EXAS.Top.start_link

    for _ <- 1..10000 do
      EXAS.Top.measure [:exas, :uuid, :v4] do
        EXAS.Identifier.new_uuid_v4
      end
    end

    measuring_points = EXAS.Top.retrieve
    [measuring_point] = measuring_points

    assert measuring_point.id == [:exas, :uuid, :v4]
    assert measuring_point.count == 10000
    assert measuring_point.min <= measuring_point.avg
    assert measuring_point.max >= measuring_point.avg

    EXAS.Top.reset

    measuring_points = EXAS.Top.retrieve

    assert length(measuring_points) == 0

    EXAS.Top.stop
  end

  test "multiple measuring points" do
    EXAS.Top.start_link
    
    for _ <- 1..1000 do
      EXAS.Top.measure "v1", EXAS.Identifier.new_uuid_v1
      EXAS.Top.measure "v3", EXAS.Identifier.new_uuid_v3(:oid, "test-uuid-v3")
      EXAS.Top.measure "v4", EXAS.Identifier.new_uuid_v4
      EXAS.Top.measure "v5", EXAS.Identifier.new_uuid_v5(:oid, "test-uuid-v5")
    end

    measurings = EXAS.Top.retrieve

    assert length(measurings) == 4

    measurings = EXAS.Top.retrieve(fn mp -> mp.id == "v3" end)

    assert length(measurings) == 1

    measurings = EXAS.Top.retrieve(fn mp -> mp.id == "not-there" end)

    assert length(measurings) == 0

    EXAS.Top.reset

    measurings = EXAS.Top.retrieve

    assert length(measurings) == 0

    EXAS.Top.stop
  end

  test "ping the Top" do
    EXAS.Top.start_link

		assert {:ok, {pid, _}} = EXAS.Ping.ping(EXAS.Top)
		assert Process.whereis(EXAS.Top) == pid

  	EXAS.Top.stop
  end

end

# --------------------
# EOF
# --------------------
