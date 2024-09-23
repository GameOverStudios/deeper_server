defmodule DeeperServerWeb.Nostr.NostrConnectController do
  use DeeperServerWeb, :controller

  alias DeeperServer.Nostr.Event
  alias DeeperServer.Nostr.Client

  action_fallback DeeperServerWeb.FallbackController

  def connect(conn, %{"event" => event_params}) do
    with {:ok, app_key} <- find_app_key(event_params["pubkey"]),
         {:ok, event} <- verify_event(event_params, app_key),
         {:ok, _} <- publish_response_event(conn, event) do
      conn
      |> put_status(:ok)
      |> json(%{message: "Conexão Nostr Connect estabelecida com sucesso!", event: event})
    else
      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{message: "Falha na conexão Nostr Connect: #{reason}"})
    end
  end

  defp find_app_key(public_key) do
    # ... lógica para buscar a chave pública da aplicação no banco de dados ...
  end

  defp verify_event(event, app_key) do
    case Event.verify(event, app_key.public_key) do
      true ->
        # ... lógica para processar o evento de conexão Nostr Connect ...
        {:ok, :valid_signature}

      false ->
        {:error, :invalid_signature}
    end
  end

  defp publish_response_event(conn, event) do
    with {:ok, user_key} <- find_user_key(conn),
         {:ok, response_event} <-
           Event.build(
             4,
             [
               {"p", [event["pubkey"]]}
             ],
             "Conexão autorizada.",
             user_key.private_key
           ),
         {:ok, _} <- publish_to_relays(response_event) do
      {:ok, response_event}
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
