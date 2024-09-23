defmodule DeeperServerWeb.Nostr.DMControllerTest do
  use DeeperServerWeb.ConnCase

  alias DeeperServer.Factory

  test "POST /api/dms envia uma mensagem direta criptografada", %{conn: conn} do
    sender_key = Factory.insert(:nostr_key)
    recipient_key = Factory.insert(:nostr_key)

    conn =
      conn
      |> put_session(:user_id, sender_key.id)
      |> post(Routes.nostr_dm_path(conn, :create), %{
        "recipient_public_key" => recipient_key.public_key,
        "message" => "Mensagem secreta!"
      })

    assert %{"message" => "Mensagem direta enviada com sucesso!", "event" => _} = json_response(conn, 201)
  end
end