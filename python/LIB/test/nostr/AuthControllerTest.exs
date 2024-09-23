defmodule DeeperServerWeb.Nostr.AuthControllerTest do
  use DeeperServerWeb.ConnCase

  alias DeeperServer.Nostr.AuthFixtures

  test "POST /api/auth autentica usuário com evento válido", %{conn: conn} do
    key = AuthFixtures.key_fixture()
    event = AuthFixtures.event_fixture(key)

    conn =
      conn
      |> post(Routes.nostr_auth_path(conn, :authenticate), %{
        "public_key" => key.public_key,
        "event" => event
      })

    assert %{"message" => "Usuário autenticado com sucesso!", "event" => _} = json_response(conn, 200)
  end

  test "POST /api/auth retorna erro para evento inválido", %{conn: conn} do
    conn =
      conn
      |> post(Routes.nostr_auth_path(conn, :authenticate), %{
        "public_key" => "npub1...",
        "event" => %{}
      })

    assert %{"message" => "Falha na autenticação: :key_not_found"} = json_response(conn, 401)
  end
end
