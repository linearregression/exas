# --------------------
# Tideland Elixir Application Support - SSV - Tests
# Copyright (C) 2014-2015 Frank Mueller / Tideland / Oldenburg / Germany
# --------------------

defmodule EXAS.SSVTest do
  use ExUnit.Case, async: true

  test "set one value" do
    EXAS.SSV.start_link

    EXAS.SSV.set(:v1, 1)
    EXAS.SSV.set(:v1, -1)
    EXAS.SSV.set(:v1, 0)

    settings = EXAS.SSV.retrieve
    [setting] = settings 

    assert setting.id == :v1
    assert setting.count == 3
    assert setting.avg == 0.0

    assert setting.act.value == 0.0
    assert setting.min.value == -1.0
    assert setting.max.value == 1.0
    
    EXAS.SSV.stop
  end

  test "set multiple values and retrieve filtered" do
    EXAS.SSV.start_link

		for id <- [:v1, :v2, :v3, :v4, :v5] do
			for v <- [-2, -1, 0, 1, 2, 3, 4], do: EXAS.SSV.set(id, v)
		end

    settings = EXAS.SSV.retrieve(fn s -> s.id in [:v2, :v4] end)
    
    assert length(settings) == 2
    
    for s <- settings do
    	assert s.id in [:v2, :v4]
    end
    
    EXAS.SSV.stop
  end

  test "ping the SSV" do
    EXAS.SSV.start_link

		assert {:ok, {pid, _}} = EXAS.Ping.ping(EXAS.SSV)
		assert Process.whereis(EXAS.SSV) == pid

  	EXAS.SSV.stop
  end

end

# --------------------
# EOF
# --------------------
