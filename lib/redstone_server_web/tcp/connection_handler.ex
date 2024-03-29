defmodule RedstoneServerWeb.Tcp.ConnectionHandler do
  @moduledoc """
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
    {:ok, data} = Cyanide.decode(packet)

    result =
      data
      |> RedstoneServerWeb.Tcp.Controller.process()
      |> wrap_response()
      |> serialize()

    :ok = :gen_tcp.send(socket, result)
    {:noreply, %{socket: socket, last_msg: data}}
  end

  def handle_info({:tcp_closed, _}, state) do
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _}, state) do
    # fallback file update transaction
    {:stop, :normal, state}
  end

  defp wrap_response(response) do
    case response do
      {:error, error} -> %{status: "error", reason: error}
      :retry -> %{status: "ok", retry: true}
      :ok -> %{status: "ok"}
      raw_data -> raw_data
    end
  end

  defp serialize(data) when is_map(data), do: Cyanide.encode!(data)
  defp serialize(data), do: data
end
