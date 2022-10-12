defmodule RedstoneServerWeb.Api.Upload do
  use RedstoneServerWeb, :controller
  
  def declare(conn, params) do
    params["files"]
      |> IO.inspect()
      |> get_total_size
      |> IO.inspect()

    conn |> send_resp(200, "")
  end

  defp get_total_size(files) do
    files
      |> Enum.map(fn 
        %{"File" => file} -> file["size"]
        %{"Folder" => folder} -> get_total_size(folder["items"]) 
      end)
      |> List.flatten
      |> Enum.sum
  end

end
