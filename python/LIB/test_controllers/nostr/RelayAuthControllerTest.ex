defmodule DeeperServerWeb.Nostr.RelayAuthControllerTest do
  use DeeperServerWeb.ConnCase

  alias DeeperServer.Factory
  alias DeeperServer.Nostr.Event

  test "POST /api/relays/auth autentica relay com evento válido", %{conn: conn} do
    relay_key = Factory.insert(:nostr_key)
    event = Factory.build(:nostr_event, kind: 2, key: relay_key, content: "") |> Event.sign(relay_key.private_key)

    conn =
      conn
      |> post(Routes.nostr_relay_auth_path(conn, :authenticate), %{"event" => event})

    assert %{"message" => "Relay autenticado com sucesso!", "event" => _} = json_response(conn, 200)
  end

  test "POST /api/relays/auth retorna erro para evento inválido", %{conn: conn} do
    relay_key = Factory.insert(:nostr_key)
    event = Factory.build(:nostr_event, kind: 2, key: relay_key, content: "", sig: <<0::256>>)

    conn =
      conn
      |> post(Routes.nostr_relay_auth_path(conn, :authenticate), %{"event" => event})

    assert %{"message" => "Falha na autenticação do relay: :invalid_signature"} = json_response(conn, 401)
  end
end
