defmodule RedstoneServer.Repo do
  use Ecto.Repo,
    otp_app: :redstone_server,
    adapter: Ecto.Adapters.Postgres
end
