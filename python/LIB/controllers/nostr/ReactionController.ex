defmodule DeeperServerWeb.Nostr.ReactionController do
  use DeeperServerWeb, :controller

  alias DeeperServer.Nostr.Event
  alias DeeperServer.Nostr.Reaction
  import Ecto.Query

  action_fallback DeeperServerWeb.FallbackController

  def create(conn, %{"id" => event_id, "reaction" => reaction}) do
    with {:ok, event} <- find_event(event_id),
         {:ok, reaction} <- create_reaction(conn, event, reaction),
         {:ok, _} <- publish_reaction_event(conn, event, reaction) do
      conn
      |> put_status(:created)
      |> json(%{message: "Reação adicionada com sucesso!", reaction: reaction})
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{message: "Falha ao adicionar reação: #{reason}"})
    end
  end

  def index(conn, %{"id" => event_id}) do
    with {:ok, _event} <- find_event(event_id) do
      reactions =
        Reaction
        |> where(event_id: ^event_id)
        |> group_by([:reaction])
        |> select(merge: %{reaction: :reaction, count: count()}) # Corrige a cláusula select
        |> Repo.all()

      conn
      |> put_status(:ok)
      |> json(%{reactions: reactions})
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{message: "Falha ao buscar reações: #{reason}"})
    end
  end

  defp find_event(event_id) do
    case DeeperServer.Repo.get(Event, event_id) do
      nil -> {:error, :event_not_found}
      event -> {:ok, event}
    end
  end

  defp create_reaction(conn, event, reaction) do
    with {:ok, user_key} <- find_user_key(conn),
         {:ok, reaction} <-
           %Reaction{}
           |> Reaction.changeset(%{
             event_id: event.id,
             public_key: user_key.public_key,
             reaction: reaction
           })
           |> DeeperServer.Repo.insert() do
      {:ok, reaction}
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

  defp publish_reaction_event(conn, event, reaction) do
    with {:ok, user_key} <- find_user_key(conn),
         {:ok, reaction_event} <-
           Event.build(
             7,
             [
               {"e", [event.id]},
               {"p", [event.public_key]}
             ],
             reaction.reaction,
             user_key.private_key
           ),
         {:ok, _} <- publish_to_relays(reaction_event) do
      {:ok, reaction_event}
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
