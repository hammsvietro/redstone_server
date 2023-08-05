defmodule RedstoneServerWeb.Websocket.Server do
  @moduledoc """
  Websocket server
  """

  @behaviour :cowboy_websocket

  # TODO: Handle auth here 
  @impl true
  def init(req, _state) do
    {:cowboy_websocket, req, %{}}
  end

  @impl true
  def websocket_init(state) do
    {:ok, state}
  end

  @impl true
  def websocket_handle({:binary, message}, state) do
    {:reply, {:text, "hello world"}, state}
  end

  @impl true
  def websocket_handle({:text, frame}, state) do
    {:ok, data} = Jason.decode(frame)

    {:reply, {:text, "hello world"}, state}
  end

  @impl true
  def websocket_info(_info, state), do: {:reply, state}

  @impl true
  def terminate(_reason, _req, _state), do: :ok

  defp wrap_json(response) do
    case response do
      {:error, error} -> %{status: "error", reason: error}
      :retry -> %{status: "ok", retry: true}
      :ok -> %{status: "ok"}
      {:ok, data} when is_map(data) -> Map.merge(%{status: "ok"}, data)
    end
  end
end
