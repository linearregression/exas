# --------------------
# Tideland Elixir Application Support - DSR
# Copyright (C) 2014-2015 Frank Mueller / Tideland / Oldenburg / Germany
# --------------------

defmodule EXAS.DSR do

  @moduledoc """
  DSR provides a dynamic status retriever. It allows to register functions
  which will be called in case of a status retrieval. Their intention is to
  return individual status values, e.g. by communicating with a process.
  """

  defmodule Status do
    defstruct id: nil, status: nil, value: nil
  end

  # --------------------
  # PUBLIC API
  # --------------------

  @doc """
  Starts the DSR server.
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
  Register a status retrieval function.
  """
  def register(rid, retriever) do
    GenServer.cast(__MODULE__, {:register, rid, retriever})
  end

  @doc """
  Delete a status retrieval function.
  """
  def delete(rid) do
    GenServer.cast(__MODULE__, {:delete, rid})
  end

  @doc """
  Retrieve the status results. They are returned as a list of
  Status structs. Also a filter can be passed.
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
    {:ok, []}
  end

  @doc """
  Handle synchronous messages.
  """
  def handle_call({:retrieve, filter}, _from, retrievers) do
    # Return the retrieved values filtered with the passed fun.
    states = retrieve_states(retrievers) |> Enum.filter(filter)
    {:reply, states, retrievers}
  end
  def handle_call(:retrieve, _from, retrievers) do
    # Retrieve the states and return them.
    states = retrieve_states(retrievers)
    {:reply, states, retrievers}
  end
  def handle_call(:stop, _from, retrievers) do
    # Stop the server.
    {:stop, :normal, :stopped, retrievers}
  end

  @doc """
  Handle asynchronous messages.
  """
  def handle_cast({:register, rid, retriever}, retrievers) do
    # Register a retriever.
    retrievers = Dict.put(retrievers, rid, retriever)
    {:noreply, retrievers}
  end
  def handle_cast({:delete, rid}, retrievers) do
    # Delete a registered retriever.
    retrievers = Dict.delete(retrievers, rid)
    {:noreply, retrievers}
  end
  def handle_cast(:reset, _) do
    # Reset all retrievers.
    {:noreply, []}
  end

  @doc """
  Handle info messages.
  """
  def handle_info({:ping, pinger_pid}, retrievers) do
    # Answer to a ping.
    EXAS.Ping.pong(pinger_pid)
    {:noreply, retrievers}
  end

	@doc """
	Terminate the server.
	"""
	def terminate(_reason, _retrievers) do
		:ok
	end

  # --------------------
  # PRIVATE
  # --------------------

  # Retrieve all states.
  defp retrieve_states(retrievers) do
  	retrievers
  	|> Enum.map(fn {id, retriever} -> retrieve_status(id, retriever) end)
    |> Enum.sort(fn {_, {a, _}}, {_, {b, _}} -> a < b end)
  end

	# Retrieve one status.
	defp retrieve_status(id, retriever) do
		try do
			status = retriever.()
  		{:ok, {id, status}}
		catch
			_, reason -> {:error, {id, reason}}
		end
	end

end

# --------------------
# EOF
# --------------------
