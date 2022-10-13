defmodule RedstoneServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      RedstoneServer.Repo,
      # Start the Telemetry supervisor
      RedstoneServerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: RedstoneServer.PubSub},
      # Start the Endpoint (http/https)
      RedstoneServerWeb.Endpoint,
      # Start the Tcp server
      {RedstoneServerWeb.Tcp.Server, 8000},
      # Start dynamic supervisor for handling tcp connection
      {DynamicSupervisor, strategy: :one_for_one, name: RedstoneServer.TcpConnectionSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RedstoneServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RedstoneServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
