defmodule DeeperServerWeb.Nostr.ReportControllerTest do
  use DeeperServerWeb.ConnCase

  alias DeeperServer.Factory

  test "POST /api/events/:id/reports cria um relatório de evento", %{conn: conn} do
    key = Factory.insert(:nostr_key)
    event = Factory.insert(:nostr_event)
    conn = put_session(conn, :user_id, key.id)

    conn =
      conn
      |> post(Routes.nostr_event_report_path(conn, :create, event.id), %{
        "reason" => "Conteúdo impróprio"
      })

    assert %{"message" => "Evento denunciado com sucesso!", "report" => _} = json_response(conn, 201)
  end
end
