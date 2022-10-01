defmodule RedstoneServerWeb.Api.Schemas.UserLogin do
  use Ecto.Schema
  import Ecto.Changeset

  def validate_user_login(params) do
    login = %{}
    types = %{email: :string, password: :string}

    {login, types}
    |> cast(params, Map.keys(types))
    |> validate_required([:email, :password])
    |> validate_length(:password, min: 12, message: "should be at least 12 chars")
  end
end
