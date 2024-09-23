defmodule DeeperServerWeb.Nostr.LongformControllerTest do
  use DeeperServerWeb.ConnCase

  alias DeeperServer.Factory

  test "POST /api/longform cria um evento de formato longo", %{conn: conn} do
    key = Factory.insert(:nostr_key)
    conn = put_session(conn, :user_id, key.id)

    conn =
      conn
      |> post(Routes.nostr_longform_path(conn, :create), %{
        "content" => "Este é um conteúdo de formato longo."
      })

    assert %{"message" => "Conteúdo de formato longo publicado com sucesso!", "event" => _} = json_response(conn, 201)
  end
end
