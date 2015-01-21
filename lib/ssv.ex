# --------------------
# Tideland Elixir Application Support - SSV
# Copyright (C) 2014-2015 Frank Mueller / Tideland / Oldenburg / Germany
# --------------------

defmodule EXAS.SSV do

  @moduledoc """
  SSV provides a stay-set variable service to monitor numerical values
  together with their lowest and highest values.
  """

  defmodule Variable do
    defstruct id: nil, act: {0.0, :os.timestamp()}, min: {0.0, :os.timestamp()}, max: {0.0, :os.timestamp()}, count: 1, avg: 0.0
  end

  # --------------------
  # PUBLIC API
  # --------------------

  @doc """
  Starts the SSV server.
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Sttop the top server.
  """
  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  @doc """
  Set a variable value.
  """
  def set(vid, value) when is_float(value) do
    now = :os.timestamp()
    GenServer.cast(__MODULE__, {:set, vid, value, now})
  end
  def set(vid, value) when is_integer(value) do
    set(vid, value * 1.0)
  end

  @doc """
  Increment a variable by 1.0.
  """
  def increase(vid) do
    now = :os.timestamp()
    GenServer.cast(__MODULE__, {:change, vid, 1.0, now})
  end

  @doc """
  Decrement a variable by 1.0.
  """
  def decrease(vid) do
    now = :os.timestamp()
    GenServer.cast(__MODULE__, {:change, vid, -1.0, now})
  end

  @doc """
  Retrieve the setting results. They are returned as a list of
  Variable structs. Also a filter can be passed.
  """
  def retrieve(filter) when is_function(filter) do
    GenServer.call(__MODULE__, {:retrieve, filter}, 5000)
  end

  def retrieve do
    GenServer.call(__MODULE__, :retrieve, 5000)
  end

  @doc """
  Reset all settings.
  """
  def reset do
    GenServer.cast(__MODULE__, :reset)
  end

  # --------------------
  # PUBLIC CALLBACKS
  # --------------------

  @doc """
  Initialize the server.
  """
  def init(_args) do
    {:ok, HashDict.new}
  end

  @doc """
  Handle synchronous messages.
  """
  def handle_call({:retrieve, filter}, _from, variables) do
    # Return the variables filtered with the passed fun.
    reply = variables |> Dict.values |> Enum.filter(filter)
    {:reply, reply, variables}
  end
  def handle_call(:retrieve, _from, variables) do
    # Return the variables.
    reply = variables |> Dict.values
    {:reply, reply, variables}
  end
  def handle_call(:stop, _from, variables) do
    # Stop the server.
    {:stop, :normal, :stopped, variables}
  end

  @doc """
  Handle asynchronous messages.
  """
  def handle_cast({:set, vid, value, ts}, variables) do
    # Set a value.
    initial = %Variable{
      id: vid,
      act: {value, ts},
      min: {value, ts},
      max: {value, ts},
      avg: value,
    }
    updater = make_updater(fn _ -> value end, ts)
    new_variables = Dict.update(variables, vid, initial, updater)
    {:noreply, new_variables}
  end
  def handle_cast({:change, vid, change, ts}, variables) do
    # Increase or decrease a value.
    act = 0.0 + change
    initial = %Variable{
      id: vid,
      act: {act, ts},
      min: {act, ts},
      max: {act, ts},
      avg: act,
    }
    updater = make_updater(&(&1 + change), ts)
    new_variables = Dict.update(variables, vid, initial, updater)
    {:noreply, new_variables}
  end
  def handle_cast(:reset, _) do
    # Reset all collected values.
    {:noreply, HashDict.new}
  end

  @doc """
  Handle info messages.
  """
  def handle_info({:ping, pinger_pid}, variables) do
    # Answer to a ping.
    EXAS.Ping.pong(pinger_pid)
    {:noreply, variables}
  end

	@doc """
	Terminate the server.
	"""
	def terminate(_reason, _variables) do
		:ok
	end

  # --------------------
  # PRIVATE
  # --------------------

  # Make an update function based on a changer function
  # and a timestamp.
  defp make_updater(changer, ts) do
    fn old_variable ->
      {old, _} = old_variable.act
      {old_min, old_min_ts} = old_variable.min
      {old_max, old_max_ts} = old_variable.max
      act = changer.(old)
      min = cond do
        act < old_min -> {act, ts}
        true          -> {old_min, old_min_ts}
      end
      max = cond do
        act > old_max -> {act, ts}
        true          -> {old_max, old_max_ts}
      end
      count = old_variable.count + 1
      avg = (old_variable.avg * old_variable.count + act) / count
      %Variable{
        id: old_variable.id,
        act: {act, ts},
        min: min,
        max: max,
        count: count,
        avg: avg,
      }
    end
  end

end

# --------------------
# EOF
# --------------------
