defmodule DeeperServerWeb.Nostr.RelayListControllerTest do
  use DeeperServerWeb.ConnCase

  test "POST /api/relay_lists cria uma nova lista de relays", %{conn: conn} do
    conn =
      conn
      |> post(Routes.nostr_relay_list_path(conn, :create), %{
        "relay_list" => %{
          "name" => "Minha Lista de Relays",
          "description" => "Uma lista de relays confiáveis",
          "relays" => ["wss://relay.damus.io", "wss://nostr-pub.wellorder.net"]
        }
      })

    assert %{"message" => "Lista de relays criada com sucesso!", "relay_list" => _} = json_response(conn, 201)
  end

  test "GET /api/relay_lists/:id retorna uma lista de relays", %{conn: conn} do
    relay_list = Factory.insert(:nostr_relay_list)
    conn = get(conn, Routes.nostr_relay_list_path(conn, :show, relay_list.id))
    assert %{"relay_list" => _} = json_response(conn, 200)
  end
end
