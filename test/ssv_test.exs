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

    assert {0.0, _} = setting.act
    assert {-1.0, _} = setting.min
    assert {1.0, _} = setting.max
    assert {1.0, _} = setting.max
    
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
