defmodule DeeperServerWeb.Nostr.ReportController do
  use DeeperServerWeb, :controller

  alias DeeperServer.Nostr.Event
  alias DeeperServer.Nostr.Report

  action_fallback DeeperServerWeb.FallbackController

  def create(conn, %{"id" => event_id, "reason" => reason}) do
    with {:ok, event} <- find_event(event_id),
         {:ok, report} <- create_report(conn, event, reason),
         {:ok, _} <- publish_report_event(conn, event, reason) do
      conn
      |> put_status(:created)
      |> json(%{message: "Evento denunciado com sucesso!", report: report})
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{message: "Falha ao denunciar evento: #{reason}"})
    end
  end

  defp find_event(event_id) do
    case DeeperServer.Repo.get(Event, event_id) do
      nil -> {:error, :event_not_found}
      event -> {:ok, event}
    end
  end

  defp create_report(conn, event, reason) do
    with {:ok, user_key} <- find_user_key(conn),
         {:ok, report} <-
           %Report{}
           |> Report.changeset(%{
             event_id: event.id,
             public_key: user_key.public_key,
             reason: reason
           })
           |> DeeperServer.Repo.insert() do
      {:ok, report}
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

  defp publish_report_event(conn, event, reason) do
    with {:ok, user_key} <- find_user_key(conn),
         {:ok, report_event} <-
           Event.build(
             8,
             [
               {"e", [event.id]},
               {"p", [event.public_key]}
             ],
             reason,
             user_key.private_key
           ),
         {:ok, _} <- publish_to_relays(report_event) do
      {:ok, report_event}
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