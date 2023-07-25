defmodule RedstoneServerWeb.Websocket.Server do
  @moduledoc """
  Websocket server
  """

  @behaviour :cowboy_websocket

  # WARNING: Handle auth here 
  def init(req, state) do
    {:cowboy_websocket, req, %{user: 123}}
  end

  @impl :cowboy_websocket
  def websocket_init(state) do
    {:ok, state}
  end

  def websocket_handle({:text, message}, state) do
    {:reply, {:text, "hello world"}, state}
  end

  def websocket_handle({:json, _}, state) do
    {:reply, {:text, "hello world"}, state}
  end

  def websocket_info(info, state) do
    {:reply, state}
  end

  def terminate(_reason, _req, _state) do
    :ok
  end
end
