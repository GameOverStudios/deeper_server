defmodule DeeperServerWeb.Nostr.DMController do
  use DeeperServerWeb, :controller

  alias DeeperServer.Nostr.DirectMessage
  alias DeeperServer.Nostr.Client

  action_fallback DeeperServerWeb.FallbackController

  def create(conn, %{"recipient_public_key" => recipient_public_key, "message" => message}) do
    with {:ok, sender_key} <- find_sender_key(conn),
         {:ok, event} <- build_dm_event(sender_key, recipient_public_key, message),
         {:ok, _} <- publish_to_relays(event) do
      conn
      |> put_status(:created)
      |> json(%{message: "Mensagem direta enviada com sucesso!", event: event})
    else
      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{message: "Falha ao enviar mensagem direta: #{reason}"})
    end
  end

  defp find_sender_key(conn) do
    case conn.assigns[:current_user] do
      %{key: key} -> {:ok, key}
      _ -> {:error, :user_not_authenticated}
    end
  end

  defp build_dm_event(sender_key, recipient_public_key, message) do
    with {:ok, event} <- DirectMessage.create_encrypted_dm_event(message, sender_key.private_key, recipient_public_key) do
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
