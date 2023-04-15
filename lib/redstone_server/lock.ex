defmodule RedstoneServer.Lock do
  @moduledoc """
  MRSW lock for backups.


  Reference: https://en.wikipedia.org/wiki/Readers-writer_lock
  """

  use GenServer

  # Server

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:lock, backup_name, :write}, _from, state) do
    case Map.get(state, backup_name) do
      nil ->
        {:reply, :ok, Map.put(state, backup_name, %{kind: :write, users: 1})}

      lock ->
        {:reply, lock_conflict_error(backup_name, lock.kind, :write), state}
    end
  end

  @impl true
  def handle_call({:lock, backup_name, :read}, _from, state) do
    case Map.get(state, backup_name) do
      %{kind: :write} ->
        {:reply, lock_conflict_error(backup_name, :write, :read), state}

      nil ->
        {:reply, :ok, Map.put(state, backup_name, %{kind: :read, users: 1})}

      lock ->
        {:reply, :ok, Map.put(state, backup_name, %{kind: :read, users: lock.users + 1})}
    end
  end

  @impl true
  def handle_call({:unlock, backup_name}, _from, state) do
    case Map.get(state, backup_name) do
      nil ->
        {:reply, {:error, "Backup isn't locked"}, state}

      lock when lock.users > 1 ->
        {:reply, :ok, Map.put(state, backup_name, %{kind: :read, users: lock.users - 1})}

      _ ->
        {:reply, :ok, Map.delete(state, backup_name)}
    end
  end

  @impl true
  def handle_call({:get, backup_name}, _from, state) do
    {:reply, Map.get(state, backup_name), state}
  end

  # Client

  @doc """
  Acquire a lock for a backup.

  Before interacting with backup data, this lock must be used.
  """
  def lock(%{backup_name: backup_name, kind: lock_kind}) do
    GenServer.call(__MODULE__, {:lock, backup_name, lock_kind})
  end

  @doc """
  Release an existing lock 

  After interacting with backup data, this must be used.
  """
  def unlock(backup_name) do
    GenServer.call(__MODULE__, {:unlock, backup_name})
  end

  def has_read_lock(backup_name),
    do: match?(%{kind: :read}, GenServer.call(__MODULE__, {:get, backup_name}))

  def has_write_lock(backup_name),
    do: match?(%{kind: :write}, GenServer.call(__MODULE__, {:get, backup_name}))

  defp lock_conflict_error(backup_name, existing_lock, lock),
    do:
      {:error,
       "Can't acquire #{lock} lock, \"#{backup_name}\" is already locked with a #{existing_lock} lock, try again later."}
end
