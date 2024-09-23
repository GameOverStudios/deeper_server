defmodule DeeperServerWeb.Nostr.SysOpController do
  use DeeperServerWeb, :controller

  alias DeeperServer.Nostr.Event
  alias DeeperServer.Nostr.Client

  action_fallback DeeperServerWeb.FallbackController

  plug :verify_sysop

  def create_message(conn, %{"recipient_public_key" => recipient_public_key, "message" => message}) do
    with {:ok, event} <- build_sysop_message_event(conn, recipient_public_key, message),
         {:ok, _} <- publish_to_relays(event) do
      conn
      |> put_status(:created)
      |> json(%{message: "Mensagem SysOp enviada com sucesso!", event: event})
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{message: "Falha ao enviar mensagem SysOp: #{reason}"})
    end
  end

  defp verify_sysop(conn, _) do
    case conn.assigns[:current_user] do
      %{sysop: true} -> conn
      _ -> conn |> send_resp(403, "Acesso negado.")
    end
  end

  defp build_sysop_message_event(conn, recipient_public_key, message) do
    with {:ok, user_key} <- find_user_key(conn),
         {:ok, event} <-
           Event.build(
             4,
             [
               {"p", [recipient_public_key]},
               {"t", ["sysop"]}
             ],
             message,
             user_key.private_key
           ) do
      {:ok, event}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp find_user_key(conn) do
    case conn.assigns[:current_user] do
      %{key: key} -> {:ok, key}
      _ -> {:error, :user_not_authenticated}
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
