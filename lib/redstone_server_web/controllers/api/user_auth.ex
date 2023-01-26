defmodule RedstoneServerWeb.Api.UserAuth do
  @moduledoc """
  Authentication API controller
  """

  use RedstoneServerWeb, :controller

  import RedstoneServerWeb.Api.Schemas.UserAuth, only: [validate_user_login: 1]
  alias RedstoneServer.Accounts.User
  alias RedstoneServer.Accounts
  alias RedstoneServerWeb.UserAuth

  def login(conn, params) do
    case validate_user_login(params) do
      %{
        valid?: true,
        changes: %{email: email, password: password}
      } ->
        case Accounts.get_user_by_email_and_password(email, password) do
          %User{} = user ->
            token = Accounts.generate_user_session_token(user)

            conn
            |> UserAuth.write_login_cookies(token)
            |> send_resp(200, "")

          nil ->
            conn
            |> send_resp(403, "")
        end

      changeset ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(RedstoneServerWeb.ErrorView, "error.json", changeset: changeset)
    end
  end

  def logout(conn, _params) do
    conn
    |> UserAuth.log_out_user()
    |> send_resp(200, "")
  end

  def test_auth(conn, _params) do
    send_resp(conn, 200, "")
  end
end
