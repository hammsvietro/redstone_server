defmodule RedstoneServerWeb.Tcp.Server do
  require Logger
  use Task

  def start_link(port) do
    Task.start_link(__MODULE__, :accept, [port])
  end

  def accept(port) do
    {:ok, listen_socket} =
      :gen_tcp.listen(
        port,
        [:binary, packet: 4, reuseaddr: true]
      )

    loop_acceptor(listen_socket)
  end

  defp loop_acceptor(listen_socket) do
    {:ok, socket} = :gen_tcp.accept(listen_socket)

    {:ok, pid} =
      DynamicSupervisor.start_child(
        RedstoneServer.TcpConnectionSupervisor,
        {
          RedstoneServerWeb.Tcp.ConnectionHandler,
          socket
        }
      )

    :ok = :gen_tcp.controlling_process(socket, pid)
    loop_acceptor(listen_socket)
  end
end
