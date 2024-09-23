defmodule DeeperServerWeb.Nostr.RelayControllerTest do
  use DeeperServerWeb.ConnCase

  test "GET /api/relays retorna lista de relays", %{conn: conn} do
    conn = get(conn, Routes.nostr_relay_path(conn, :index))
    assert json_response(conn, 200) == %{"relays" => ["wss://relay.damus.io", "wss://nostr-pub.wellorder.net"]}
  end

  test "GET /api/relays/:relay_url retorna informações do relay", %{conn: conn} do
    relay_url = "wss://relay.damus.io"
    conn = get(conn, Routes.nostr_relay_path(conn, :show, relay_url))
    assert %{"relay" => _} = json_response(conn, 200)
  end

  test "GET /api/relays/:relay_url retorna erro para relay inválido", %{conn: conn} do
    relay_url = "wss://relay-invalido.com"
    conn = get(conn, Routes.nostr_relay_path(conn, :show, relay_url))
    assert %{"message" => "Falha ao obter informações do relay: {:failed_request, _}"} = json_response(conn, 404)
  end
end