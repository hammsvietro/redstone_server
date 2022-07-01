defmodule RedstoneServerWeb.Html.PageController do
  use RedstoneServerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
