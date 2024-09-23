defmodule DeeperServerWeb.Nostr.BoostController do
  use DeeperServerWeb, :controller

  alias DeeperServer.Nostr.Event
  alias DeeperServer.Nostr.Client

  action_fallback DeeperServerWeb.FallbackController

  def create(conn, %{"id" => event_id}) do
    with {:ok, event} <- find_event(event_id),
         {:ok, boost_event} <- create_boost_event(conn, event),
         {:ok, _} <- publish_to_relays(boost_event) do
      conn
      |> put_status(:created)
      |> json(%{message: "Nota impulsionada com sucesso!", event: boost_event})
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{message: "Falha ao impulsionar nota: #{reason}"})
    end
  end

  defp find_event(event_id) do
    case DeeperServer.Repo.get(Event, event_id) do
      nil -> {:error, :event_not_found}
      event -> {:ok, event}
    end
  end

  defp create_boost_event(conn, event) do
    with {:ok, user_key} <- find_user_key(conn),
         {:ok, boost_event} <-
           Event.build(
             6,
             [
               {"e", [event.id]},
               {"p", [event.public_key]}
             ],
             "",
             user_key.private_key
           ) do
      {:ok, boost_event}
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
