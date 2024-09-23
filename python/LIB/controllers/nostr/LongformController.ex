defmodule DeeperServerWeb.Nostr.LongformController do
  use DeeperServerWeb, :controller

  alias DeeperServer.Nostr.LongFormContent
  alias DeeperServer.Nostr.Client

  action_fallback DeeperServerWeb.FallbackController

  def create(conn, %{"content" => content}) do
    with {:ok, sender_key} <- find_sender_key(conn),
         {:ok, event} <- build_longform_event(sender_key, content),
         {:ok, _} <- publish_to_relays(event) do
      conn
      |> put_status(:created)
      |> json(%{message: "Conteúdo de formato longo publicado com sucesso!", event: event})
    else
      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{message: "Falha ao publicar conteúdo de formato longo: #{reason}"})
    end
  end

  defp find_sender_key(conn) do
    case conn.assigns[:current_user] do
      %{key: key} -> {:ok, key}
      _ -> {:error, :user_not_authenticated}
    end
  end

  defp build_longform_event(sender_key, content) do
    with {:ok, event} <- LongFormContent.create_long_form_event(content, sender_key.private_key) do
      {:ok, event}
    else
      {:error, reason} -> {:error, reason}
    end
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
