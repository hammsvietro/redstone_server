defmodule RedstoneServerWeb.Tcp.ConnectionHandler do
  use GenServer
  require Logger

  @initial_state %{socket: nil, last_msg: nil}

  def start_link(socket, opts \\ []) do
    GenServer.start_link(__MODULE__, socket, opts)
  end

  def init(socket) do
    {:ok, %{@initial_state | socket: socket}}
  end

  # TCP callbacks
  def handle_info({:tcp, socket, data}, _state) do
    :ok = :gen_tcp.send(socket, "ACK\n")
    {:noreply, %{socket: socket, last_msg: data}}
  end

  def handle_info({:tcp_closed, _}, state) do
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _}, state) do
    # fallback file update transaction
    {:stop, :normal, state}
  end
end
