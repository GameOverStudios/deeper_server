defmodule DeeperServerWeb.Nostr.ReactionControllerTest do
  use DeeperServerWeb.ConnCase

  alias DeeperServer.Factory

  test "POST /api/events/:id/reactions cria uma reação", %{conn: conn} do
    key = Factory.insert(:nostr_key)
    event = Factory.insert(:nostr_event)
    conn = put_session(conn, :user_id, key.id)

    conn =
      conn
      |> post(Routes.nostr_event_reaction_path(conn, :create, event.id), %{
        "reaction" => "👍"
      })

    assert %{"message" => "Reação adicionada com sucesso!", "reaction" => _} = json_response(conn, 201)
  end

  test "GET /api/events/:id/reactions lista as reações de um evento", %{conn: conn} do
    event = Factory.insert(:nostr_event)
    Factory.insert(:nostr_reaction, event_id: event.id, reaction: "👍")
    Factory.insert(:nostr_reaction, event_id: event.id, reaction: "👍")
    Factory.insert(:nostr_reaction, event_id: event.id, reaction: "👎")

    conn = get(conn, Routes.nostr_event_reaction_path(conn, :index, event.id))
    assert json_response(conn, 200) == %{"reactions" => [%{"reaction" => "👍", "count" => 2}, %{"reaction" => "👎", "count" => 1}]}
  end
end
