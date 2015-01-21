# --------------------
# Tideland Elixir Application Support - Ping - Tests
# Copyright (C) 2014-2015 Frank Mueller / Tideland / Oldenburg / Germany
# --------------------

defmodule EXAS.PingTest do
  use ExUnit.Case, async: true

  test "ping valid process" do
    pinger_pid = spawn &pinger_loop/0
    
    {:ok, {pid, ts_a}} = EXAS.Ping.ping pinger_pid
    
    assert pid == pinger_pid

    {:ok, {pid, ts_b}} = EXAS.Ping.ping pinger_pid
    
    assert pid == pinger_pid
    assert ts_a != ts_b

		send pinger_pid, :exit
  end

  test "ping invalid process" do
    pinger_pid = spawn &pinger_loop/0
    
    {:ok, {pid, _}} = EXAS.Ping.ping pinger_pid
    
    assert pid == pinger_pid

		send pinger_pid, :exit

    {:error, :timeout} = EXAS.Ping.ping pinger_pid
  end

  # --------------------
  # HELPER
  # --------------------

	def pinger_loop do
		receive do
			{:ping, pinger_pid} ->
				EXAS.Ping.pong pinger_pid
				pinger_loop
			:exit ->
				:ok        
		end
	end

end

# --------------------
# EOF
# --------------------
