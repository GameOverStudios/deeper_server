defmodule DeeperServerWeb.Nostr.FileController do
  use DeeperServerWeb, :controller

  alias DeeperServer.Nostr.Event
  alias DeeperServer.Nostr.Client

  action_fallback DeeperServerWeb.FallbackController

  def create(conn, %{"file" => file, "description" => description}) do
    with {:ok, user_key} <- find_user_key(conn),
         {:ok, file_event} <- create_file_event(user_key, file, description),
         {:ok, _} <- publish_to_relays(file_event) do
      conn
      |> put_status(:created)
      |> json(%{message: "Arquivo compartilhado com sucesso!", event: file_event})
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{message: "Falha ao compartilhar arquivo: #{reason}"})
    end
  end

  defp find_user_key(conn) do
    case conn.assigns[:current_user] do
      %{key: key} -> {:ok, key}
      _ -> {:error, :user_not_authenticated}
    end
  end

  defp create_file_event(user_key, file, description) do
    # ... lógica para processar e armazenar o arquivo ...
    # ... gerar evento Nostr com metadados do arquivo ...
  end

  defp publish_to_relays(event) do
    Enum.each(Application.get_env(:deeper_server, :nostr)[:relays], fn relay_url ->
      case Client.connect(relay_url) do
        {:ok, relay_pid} ->
          Client.publish_event(relay_pid, event)
          :ok

        {:error, reason} ->
          {:error, "Falha ao conectar ao relay #{relay_url}: #{reason}"}
      end
    end)
  end
end