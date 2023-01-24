defmodule RedstoneServerWeb.ErrorView do
  use RedstoneServerWeb, :view

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  # def render("500.html", _assigns) do
  #   "Internal Server Error"
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end

  def render("error.json", %{changeset: changeset}) do
    %{
      errors: translate_errors(changeset),
      stringified_errors: RedstoneServerWeb.ErrorHelpers.changeset_error_to_string(changeset)
    }
  end

  def render("404.json", %{entity: entity, name: name}) do
    %{
      errors: %{
        entity => "\"#{name}\" not found"
      },
      stringified_errors: "#{entity} \"#{name}\" not found"
    }
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end
end
