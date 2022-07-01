defmodule RedstoneServer.Udp do
  use GenServer

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, name: :udp_server)
  end

  @impl true
  def init(port), do: :gen_udp.open(port)

  @impl true
  def handle_info({:udp, client_socket, host, port, message}, socket) do
    :gen_udp.send(client_socket, {host, port}, message)
    {:noreply, socket}
  end
end
