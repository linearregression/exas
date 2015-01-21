# --------------------
# Tideland Elixir Application Support - Monitoring
# Copyright (C) 2014-2015 Frank Mueller / Tideland / Oldenburg / Germany
# --------------------

defmodule EXAS.Monitoring do
  use Supervisor

  @moduledoc """
  Monitoring starts the monitoring modules SSI and Top and keeps
  them running.
  """

  # --------------------
  # PUBLIC API
  # --------------------

  @doc """
  Starts the monitoring supervisor.
  """
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # --------------------
  # PUBLIC CALLBACKS
  # --------------------

  @doc """
  Initialize the supervisor.
  """
  def init([]) do
    children = [
      worker(EXAS.DSR, []),
      worker(EXAS.SSI, []),
      worker(EXAS.Top, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

end

# --------------------
# EOF
# --------------------
