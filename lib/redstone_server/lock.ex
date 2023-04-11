defmodule RedstoneServer.Lock do
  @moduledoc """
  MRSW lock for backups.


  Reference: https://en.wikipedia.org/wiki/Readers-writer_lock
  """

  use GenServer

  # Server
  @impl true
  def init(%{backup_name: name, kind: :read}) do
    {:ok, %{backup_name: name, kind: :read, users: 1}}
  end

  @impl true
  def init(%{backup_name: name, kind: :write}) do
    {:ok, %{backup_name: name, kind: :write, users: 1}}
  end

  @impl true
  def handle_cast(:add_user, %{kind: :read} = state) do
    {:noreply, %{state | users: state.users + 1}}
  end

  @impl true
  def handle_call(:remove_user, _from, %{users: 1}) do
    {:stop, :normal, nil}
  end

  @impl true
  def handle_call(:remove_user, _from, %{kind: :read} = state) do
    {:reply, :ok, %{state | users: state.users - 1}}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  # Client

  @doc """
  Acquire a lock for a backup.

  Before interacting with backup data, this lock must be used.
  """
  def acquire_lock(%{backup_name: name, kind: _kind} = state) do
    case name |> get_gen_server_name() |> Process.whereis() do
      nil -> create_lock(state)
      pid when is_pid(pid) -> handle_existing_lock(pid, state)
    end
  end

  @doc """
  Release an existing lock 

  After interacting with backup data, this must be used.
  """
  def release_lock(pid) do
    try do
      GenServer.call(pid, :remove_user)
    catch
      :exit, {:normal, _} -> :ok
    end
  end

  defp create_lock(%{backup_name: name} = state) do
    GenServer.start_link(__MODULE__, state, name: get_gen_server_name(name))
  end

  defp handle_existing_lock(pid, state) do
    lock = GenServer.call(pid, :get)

    if :write in [lock.kind, state.kind] do
      {:error,
       "Can't acquire #{state.kind} lock, \"#{state.backup_name}\" is already locked with a #{lock.kind} lock"}
    else
      GenServer.cast(pid, :add_user)
      {:ok, pid}
    end
  end

  defp get_gen_server_name(backup_name), do: :"#{__MODULE__}.#{backup_name}"
end
