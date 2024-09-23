defmodule DeeperServerWeb.Nostr.SysOpControllerTest do
  use DeeperServerWeb.ConnCase

  alias DeeperServer.Factory

  test "POST /api/sysop/messages envia uma mensagem SysOp", %{conn: conn} do
    sysop_key = Factory.insert(:nostr_key)
    recipient_key = Factory.insert(:nostr_key)

    conn =
      conn
      |> put_session(:user_id, sysop_key.id)
      |> assign(:current_user, %{key: sysop_key, sysop: true}) # Simula um usuário SysOp
      |> post(Routes.nostr_sysop_message_path(conn, :create_message), %{
        "recipient_public_key" => recipient_key.public_key,
        "message" => "Mensagem secreta para SysOps!"
      })

    assert %{"message" => "Mensagem SysOp enviada com sucesso!", "event" => _} = json_response(conn, 201)
  end

  test "POST /api/sysop/messages retorna erro para usuário não SysOp", %{conn: conn} do
    key = Factory.insert(:nostr_key)
    recipient_key = Factory.insert(:nostr_key)

    conn =
      conn
      |> put_session(:user_id, key.id)
      |> post(Routes.nostr_sysop_message_path(conn, :create_message), %{
        "recipient_public_key" => recipient_key.public_key,
        "message" => "Mensagem secreta para SysOps!"
      })

    assert conn.status == 403
  end
end
