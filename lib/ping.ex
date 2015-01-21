# --------------------
# Tideland Elixir Application Support - Ping
# Copyright (C) 2014-2015 Frank Mueller / Tideland / Oldenburg / Germany
# --------------------

defmodule EXAS.Ping do

  @moduledoc """
  Ping provides a function to ping a process and to reply
  to this message with a pong.
  """

  @doc """
  Send a ping to a process and wait for its pong reply.
  """
  def ping(pid) do
    send(pid, {:ping, self()})
    receive do
      {:pong, ponger_pid, timestamp} ->
        {:ok, {ponger_pid, timestamp}}
    after
      5000 ->
        {:error, :timeout}
    end
  end
  
  @doc """
  Send a pong reply to a pinger.
  """
  def pong(pinger_pid) do
    send(pinger_pid, {:pong, self(), :os.timestamp})
  end
  
end

# --------------------
# EOF
# --------------------
