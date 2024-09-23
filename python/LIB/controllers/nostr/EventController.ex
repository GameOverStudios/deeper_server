defmodule DeeperServerWeb.Nostr.EventController do
  use DeeperServerWeb, :controller

  alias DeeperServer.Nostr.Event
  alias DeeperServer.Nostr.Client
  alias DeeperServer.Nostr.GenericTagQueries

  action_fallback DeeperServerWeb.FallbackController

  @pow_difficulty 5

  def create(conn, %{"event" => event_params, "recipient_public_key" => recipient_public_key}) do
    with {:ok, sender_key} <- find_sender_key(conn),
         {:ok, event} <- build_event(event_params, sender_key, recipient_public_key),
         {:ok, _} <- publish_to_relays(event) do
      conn
      |> put_status(:created)
      |> json(%{message: "Evento publicado com sucesso!", event: %{event | id: Event.encode_id(event.id)}})
    else
      {:error, :user_not_authenticated} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Usuário não autenticado.", code: "E001"})

      {:error, :event_creation_failed} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Falha ao criar evento.", code: "E002"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Falha ao publicar evento: #{reason}", code: "E003"})
    end
  end

  def index(conn, _params) do
    events = DeeperServer.Repo.all(Event)

    conn
    |> put_status(:ok)
    |> render("index.json", events: events)
  end

  def search(conn, %{"filters" => filters}) do
    events = DeeperServer.Repo.all(Event)
    filtered_events = GenericTagQueries.filter_events(events, filters)

    conn
    |> put_status(:ok)
    |> json(%{events: filtered_events})
  end

  defp find_sender_key(conn) do
    case conn.assigns[:current_user] do
      %{key: key} -> {:ok, key}
      _ -> {:error, :user_not_authenticated}
    end
  end

  defp build_event(event_params, sender_key, nil) do
    with {:ok, event} <- Event.create_changeset(%Event{}, event_params) |> DeeperServer.Repo.insert() do
      {:ok, event}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_event(event_params, sender_key, recipient_public_key) do
    with {:ok, event} <- Event.create_changeset(%Event{}, event_params) |> DeeperServer.Repo.insert() do
      {:ok, Event.encrypt_for_recipient(event, sender_key.private_key, recipient_public_key)}
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
