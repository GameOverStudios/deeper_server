defmodule DeeperServerWeb.Nostr.EventControllerTest do
  use DeeperServerWeb.ConnCase

  alias DeeperServer.Nostr.Event

  @valid_attrs %{
    public_key: "npub1...",
    created_at: DateTime.utc_now(),
    kind: 1,
    tags: [],
    content: "Hello, Nostr!",
    sig: "sig..."
  }
  @invalid_attrs %{public_key: nil, created_at: nil, kind: nil, tags: nil, content: nil, sig: nil}

  test "cria um novo evento com atributos válidos", %{conn: conn} do
    conn = post(conn, "/api/events", %{"event" => @valid_attrs})
    assert %{"message" => "Evento publicado com sucesso!", "event" => event} = json_response(conn, 201)

    assert event["id"]
    assert event["public_key"] == "npub1..."
    assert event["content"] == "Hello, Nostr!"
    assert event["sig"] == "sig..."
  end

  test "retorna erro para atributos inválidos", %{conn: conn} do
    conn = post(conn, "/api/events", %{"event" => @invalid_attrs})
    assert json_response(conn, 422) == %{"message" => "Falha ao publicar evento.", "errors" => _}
  end
end
