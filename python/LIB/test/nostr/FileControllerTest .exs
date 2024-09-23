defmodule DeeperServerWeb.Nostr.FileControllerTest do
  use DeeperServerWeb.ConnCase

  alias DeeperServer.Factory

  test "POST /api/files compartilha um arquivo", %{conn: conn} do
    key = Factory.insert(:nostr_key)
    conn = put_session(conn, :user_id, key.id)

    conn =
      conn
      |> post(Routes.nostr_file_path(conn, :create), %{
        "file" => %Plug.Upload{
          filename: "teste.txt",
          content_type: "text/plain",
          path: Path.join(__DIR__, "../fixtures/teste.txt")
        },
        "description" => "Arquivo de teste"
      })

    assert %{"message" => "Arquivo compartilhado com sucesso!", "event" => _} = json_response(conn, 201)
  end

  # Adicione mais testes para diferentes tipos de arquivos, erros de upload, etc.
end
