# --------------------
# Tideland Elixir Application Support - Scene
# Copyright (C) 2014-2015 Frank Mueller / Tideland / Oldenburg / Germany
# --------------------

defmodule EXAS.Scene do

  @moduledoc """
  Scene provides a shared access to common used data in a larger context.
  """

  # --------------------
  # PUBLIC API
  # --------------------

  @doc """
  Starts a scene. Two times in milliseconds may be passed. The first one
  represents a time of inactivity before a scene will be ended, the second
  one the number of milliseconds from now. If both are 0 there's no timeout.
  """
	def start_link(inactivity, absolute) do
		id = EXAS.Identifier.new_uuid_v4
		pid = spawn_link fn -> loop(id, inactivity, %{}, %{}) end
		if absolute > 0, do: :timer.send_after(absolute, pid, :absolute_timeout)
		pid
	end
  def start_link do
  	start_link(0, 0)
  end

  @doc """
  Stop the scene.
  """
  def stop(pid) do
  	send pid, :stop
  end

	@doc """
	Store a property in the scene.
	"""
	def store(pid, key, prop) do
		send pid, {:store, key, prop}
		:ok
	end

	@doc """
	Fetch a property from the scene.
	"""
	def fetch(pid, key) do
		send pid, {:fetch, key, self()}
		receive do
			{:ok, key, prop}          -> {:ok, key, prop}
			{:error, key, :not_found} -> {:error, key, :not_found}
		after
			5000 ->
				{:error, key, :timeout}
		end
	end

	@doc """
	Dispose a property from the scene.
	"""
	def dispose(pid, key) do
		send pid, {:dispose, key}
		:ok
	end

  # --------------------
  # PRIVATE
  # --------------------

	# Backend loop  of the scene.
	defp loop(id, inactivity, props, signals) do
		receive do
			{:store, key, prop} ->
				props = Dict.put(props, key, prop)
				loop(id, inactivity, props, signals)
			{:fetch, key, pid} ->
				case Dict.fetch(props, key) do
					{:ok, {prop, _}} -> send pid, {:ok, key, prop}
					:error           -> send pid, {:error, key, :not_found}
				end
				loop(id, inactivity, props, signals)
			{:dispose, key} ->
				props = Dict.delete(props, key)
				loop(id, inactivity, props, signals)
		after
			inactivity ->
				cleanup(props, signals)
		end
	end

	# Cleanup all stored properties and signals.
	defp cleanup(_props, _signals) do
	end

end

# --------------------
# EOF
# --------------------
