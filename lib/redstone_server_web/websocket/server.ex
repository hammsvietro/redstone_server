defmodule RedstoneServerWeb.Websocket.Server do
  @moduledoc """
  Websocket server
  """

  @behaviour :cowboy_websocket

  # TODO: Handle auth here 
  @impl true
  def init(req, _state) do
    {:cowboy_websocket, req, %{user: 123}}
  end

  @impl true
  def websocket_init(state) do
    {:ok, state}
  end

  @impl true
  def websocket_handle({:text, message}, state) do
    {:reply, {:text, "hello world"}, state}
  end

  @impl true
  def websocket_handle({:json, _}, state) do
    {:reply, {:text, "hello world"}, state}
  end

  @impl true
  def websocket_info(info, state) do
    {:reply, state}
  end

  @impl true
  def terminate(_reason, _req, _state) do
    :ok
  end
end
