defmodule DeeperServerWeb.Nostr.KeyControllerTest do
  use DeeperServerWeb.ConnCase

  test "POST /api/keys cria uma nova chave", %{conn: conn} do
    conn = post(conn, Routes.nostr_key_path(conn, :create), %{"public_key" => "npub1..."})
    assert %{"message" => "Chave pública registrada com sucesso!", "key" => _} = json_response(conn, 201)
  end

  test "GET /api/keys/:public_key retorna uma chave", %{conn: conn} do
    key = Factory.insert(:nostr_key, public_key: "npub1...")
    conn = get(conn, Routes.nostr_key_path(conn, :show, key.public_key))
    assert %{"key" => _} = json_response(conn, 200)
  end

  test "GET /api/keys/:public_key retorna erro para chave não encontrada", %{conn: conn} do
    conn = get(conn, Routes.nostr_key_path(conn, :show, "npub1..."))
    assert %{"message" => "Chave pública não encontrada."} = json_response(conn, 404)
  end
end