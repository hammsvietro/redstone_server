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
  def handle_info({:tcp, socket, packet}, _state) do
    {:ok, data} = packet |> Cyanide.decode()
    # TODO: handle invalid upload_token

    # backup = data["upload_token"]
    # |> RedstoneServer.Backup.get_backup_by_upload_token

    file = data["file_id"]
    |> RedstoneServer.Backup.get_file()

    # TODO calculate sha_256 checksum and see if it matches

    path = "/home/hammsvietro/backup_test/#{file.path}"
    {_file_name, folders} = path
    |> String.split("/", trim: true)
    |> List.pop_at(-1)

    file_chunk = data["data"] |> elem(1)
    :ok = File.mkdir_p("/#{Enum.join(folders, "/")}/")
    File.write(path, file_chunk, [:append, :binary])
    
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
