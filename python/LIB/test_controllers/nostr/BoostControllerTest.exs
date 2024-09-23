defmodule DeeperServerWeb.Nostr.BoostControllerTest do
  use DeeperServerWeb.ConnCase

  alias DeeperServer.Factory

  test "POST /api/events/:id/boost cria um evento de impulsionamento", %{conn: conn} do
    key = Factory.insert(:nostr_key)
    event = Factory.insert(:nostr_event)
    conn = put_session(conn, :user_id, key.id)

    conn = post(conn, Routes.nostr_event_boost_path(conn, :create, event.id))

    assert %{"message" => "Nota impulsionada com sucesso!", "event" => _} = json_response(conn, 201)
  end
end
