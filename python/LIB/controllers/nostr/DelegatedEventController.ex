defmodule DeeperServerWeb.Nostr.DelegatedEventController do
  use DeeperServerWeb, :controller

  alias DeeperServer.Nostr.DelegatedEventSigning
  alias DeeperServer.Nostr.Client

  action_fallback DeeperServerWeb.FallbackController

  def create(conn, %{
        "kind" => kind,
        "tags" => tags,
        "content" => content,
        "delegatee_public_key" => delegatee_public_key,
        "conditions" => conditions
      }) do
    with {:ok, delegator_key} <- find_sender_key(conn),
         {:ok, events} <- build_delegated_events(
           kind,
           tags,
           content,
           delegator_key.private_key,
           delegatee_public_key,
           conditions
         ),
         {:ok, _} <- publish_to_relays(events.delegation_token),
         {:ok, _} <- publish_to_relays(events.event) do
      conn
      |> put_status(:created)
      |> json(%{
        message: "Evento delegado publicado com sucesso!",
        delegation_token: events.delegation_token,
        event: events.event
      })
    else
      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{message: "Falha ao publicar evento delegado: #{reason}"})
    end
  end

  defp find_sender_key(conn) do
    case conn.assigns[:current_user] do
      %{key: key} -> {:ok, key}
      _ -> {:error, :user_not_authenticated}
    end
  end

  defp build_delegated_events(kind, tags, content, delegator_private_key, delegatee_public_key, conditions) do
    with {:ok, events} <-
           DelegatedEventSigning.create_delegated_event(
             kind,
             tags,
             content,
             delegator_private_key,
             delegatee_public_key,
             conditions
           ) do
      {:ok, events}
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
