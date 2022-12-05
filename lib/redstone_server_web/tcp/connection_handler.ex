defmodule RedstoneServerWeb.Tcp.ConnectionHandler do
  @doc """
  Genserver for handling an individual tcp connection.
  """
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
  def handle_info({:tcp, socket, packet}, _state) do
    {:ok, data} = packet |> Cyanide.decode()
    RedstoneServerWeb.Tcp.Controller.process(data)
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
