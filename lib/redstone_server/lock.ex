defmodule RedstoneServer.Lock do
  @moduledoc """
  MRSW lock for backups.


  Reference: https://en.wikipedia.org/wiki/Readers-writer_lock
  """

  use GenServer

  # Server
  @impl true
  def init(%{backup_name: name, kind: lock_kind}) do
    {:ok, %{backup_name: name, kind: lock_kind, users: 1}}
  end

  @impl true
  def handle_cast(:add_user, %{kind: :read} = state) do
    {:noreply, %{state | users: state.users + 1}}
  end

  @impl true
  def handle_cast(:remove_user, %{kind: :read} = state) do
    users = state.users - 1

    if users == 0 do
      GenServer.stop(self())
    end

    {:noreply, %{state | users: users}}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  # Client

  def start_link(%{backup_name: name} = state) do
    GenServer.start_link(__MODULE__, state, name: get_gen_server_name(name))
  end

  def acquire_lock(%{backup_name: name, kind: _kind} = state) do
    case name |> get_gen_server_name() |> Process.whereis() do
      nil -> create_lock(state)
      pid when is_pid(pid) -> handle_existing_lock(pid, state)
    end
  end

  def release_lock(pid) do
    GenServer.call(pid, :remove_user)
  end

  def create_lock(%{backup_name: name} = state) do
    {:ok, _pid} = res = GenServer.start_link(__MODULE__, state, name: get_gen_server_name(name))
    res
  end

  defp handle_existing_lock(pid, state) do
    lock = GenServer.call(pid, :get)

    if :write in [lock.kind, state.kind] do
      {:error, "Can't acquire #{state.lock} lock, #{state.backup_name} has a #{lock.kind} lock"}
    else
      GenServer.cast(pid, :add_user)
      {:ok, pid}
    end
  end

  defp get_gen_server_name(backup_name), do: :"#{__MODULE__}.#{backup_name}"
end
