defmodule DeeperServerWeb.Nostr.NostrConnectControllerTest do
  use DeeperServerWeb.ConnCase

  alias DeeperServer.Factory
  alias DeeperServer.Nostr.Event

  test "POST /api/nostr_connect estabelece conexão Nostr Connect", %{conn: conn} do
    app_key = Factory.insert(:nostr_key)
    user_key = Factory.insert(:nostr_key)
    event = Factory.build(:nostr_event, kind: 4, key: user_key, content: "{\"relay\": \"ws://relay.example.com\"}") |> Event.sign(user_key.private_key)

    conn =
      conn
      |> put_session(:user_id, user_key.id)
      |> post(Routes.nostr_nostr_connect_path(conn, :connect), %{"event" => event})

    assert %{"message" => "Conexão Nostr Connect estabelecida com sucesso!", "event" => _} = json_response(conn, 200)
  end

  test "POST /api/nostr_connect retorna erro para evento inválido", %{conn: conn} do
    app_key = Factory.insert(:nostr_key)
    user_key = Factory.insert(:nostr_key)
    event = Factory.build(:nostr_event, kind: 4, key: user_key, content: "", sig: <<0::256>>)

    conn =
      conn
      |> put_session(:user_id, user_key.id)
      |> post(Routes.nostr_nostr_connect_path(conn, :connect), %{"event" => event})

    assert %{"message" => "Falha na conexão Nostr Connect: :invalid_signature"} = json_response(conn, 401)
  end
end
