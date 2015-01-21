# --------------------
# Tideland Elixir Application Support - Top
# Copyright (C) 2014-2015 Frank Mueller / Tideland / Oldenburg / Germany
# --------------------

defmodule EXAS.Top do

  @moduledoc """
  Top provides a service to measure the execution time of code
  segments.
  """

  defmodule MeasuringPoint do
    defstruct id: nil, count: 1, min: 0, max: 0, avg: 0, total: 0
  end
  
  # --------------------
  # PUBLIC API
  # --------------------

  @doc """
  Starts the top server.
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
  Begin a measuring.
  """
  def begin_measuring(mid) do
    {mid, :os.timestamp}
  end

  @doc """
  End a begun measuring.
  """
  def end_measuring({mid, begin_ts}) do
    duration = :timer.now_diff(:os.timestamp, begin_ts)
    GenServer.cast(__MODULE__, {:add_measuring, mid, duration})
  end

  @doc """
  Convenience function to measure the execution of
  an expression of block.
  """
  defmacro measure(mid, expression) do
    quote do
      measuring = EXAS.Top.begin_measuring(unquote(mid))
      unquote(expression)
      EXAS.Top.end_measuring(measuring)
    end
  end

  @doc """
  Retrieve the measuring results. They are returned as a list of
  MeasuringPoint structs. Also a filter can be passed.
  """
  def retrieve(filter) when is_function(filter) do
    GenServer.call(__MODULE__, {:retrieve, filter}, 5000)
  end
  def retrieve do
    GenServer.call(__MODULE__, :retrieve, 5000)
  end

  @doc """
  Reset all measurings.
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
  def handle_call({:retrieve, filter}, _from, measuring_points) do
    # Return the measurings filtered with the passed fun.
    reply = measuring_points |> Dict.values |> Enum.filter(filter)
    {:reply, reply, measuring_points}
  end
  def handle_call(:retrieve, _from, measuring_points) do
    # Return the measurings.
    reply = measuring_points |> Dict.values
    {:reply, reply, measuring_points}
  end
  def handle_call(:stop, _from, measuring_points) do
    # Stop the server.
    {:stop, :normal, :stopped, measuring_points}
  end

  @doc """
  Handle asynchronous messages.
  """
  def handle_cast({:add_measuring, mid, duration}, measuring_points) do
    # Just add measuring to the raw list.
    initial = %MeasuringPoint{
      id: mid,
      count: 1,
      min: duration,
      max: duration,
      avg: duration,
      total: duration,
    }
    updater = make_updater(duration)
    new_measuring_points = Dict.update(measuring_points, mid, initial, updater)
    {:noreply, new_measuring_points}
  end
  def handle_cast(:reset, _) do
    # Reset all collected measurings.
    {:noreply, HashDict.new}
  end

  @doc """
  Handle info messages.
  """
  def handle_info({:ping, pinger_pid}, measuring_points) do
    # Answer to a ping.
    EXAS.Ping.pong(pinger_pid)
    {:noreply, measuring_points}
  end

	@doc """
	Terminate the server.
	"""
	def terminate(_reason, _measuring_points) do
		:ok
	end

  # --------------------
  # PRIVATE
  # --------------------

  # Make an update function based on a duration.
  defp make_updater(duration) do
    fn old_measuring_point ->
      min = cond do
        duration < old_measuring_point.min -> duration
        true                               -> old_measuring_point.min
      end
      max = cond do
        duration > old_measuring_point.max -> duration
        true                               -> old_measuring_point.max
      end
      count = old_measuring_point.count + 1
      total = old_measuring_point.total + duration
      avg = total / count
      %MeasuringPoint{
        id: old_measuring_point.id,
        count: count,
        min: min,
        max: max,
        avg: avg,
        total: total,
      }
    end
  end

end

# --------------------
# EOF
# --------------------
