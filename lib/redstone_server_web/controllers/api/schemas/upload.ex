defmodule RedstoneServerWeb.Api.Schemas.Upload do
  import Ecto.Changeset
  use Ecto.Schema

  def validate_backup(params) do
    backup = %{}
    types = %{name: :string, root: :string, files: :any}

    {backup, types}
    |> cast(params, Map.keys(types))
    |> validate_required([:name, :root, :files])
  end
end
