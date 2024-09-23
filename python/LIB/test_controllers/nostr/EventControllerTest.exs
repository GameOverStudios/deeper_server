defmodule DeeperServerWeb.Nostr.EventControllerTest do
  use DeeperServerWeb.ConnCase

  alias DeeperServer.Factory

  test "POST /api/delegated_events cria um evento delegado", %{conn: conn} do
    delegator_key = Factory.insert(:nostr_key)
    delegatee_public_key = "npub1..."
    conditions = %{
      "kind" => 1,
      "tags" => [{"p", ["npub2..."]}]
    }

    conn =
      conn
      |> put_session(:user_id, delegator_key.id)
      |> post(Routes.nostr_delegated_event_path(conn, :create), %{
        "kind" => 1,
        "tags" => [{"p", ["npub2..."]}],
        "content" => "Evento delegado!",
        "delegatee_public_key" => delegatee_public_key,
        "conditions" => conditions
      })

    assert %{"message" => "Evento delegado publicado com sucesso!", "delegation_token" => _, "event" => _} = json_response(conn, 201)
  end

  test "POST /api/events cria e publica um evento", %{conn: conn} do
    key = Factory.insert(:nostr_key)

    conn =
      conn
      |> post(Routes.nostr_event_path(conn, :create), %{
        "event" => %{
          "public_key" => key.public_key,
          "created_at" => DateTime.utc_now() |> DateTime.to_unix(),
          "kind" => 1,
          "tags" => [],
          "content" => "Testando a API!",
          "sig" => "sig..."
        },
        "recipient_public_key" => nil
      })

    assert %{"message" => "Evento publicado com sucesso!", "event" => _} = json_response(conn, 201)
  end

  test "GET /api/events retorna uma lista de eventos", %{conn: conn} do
    Factory.insert_list(3, :nostr_event)

    conn = get(conn, Routes.nostr_event_path(conn, :index))
    assert json_response(conn, 200)["events"] |> length() == 3
  end

  test "GET /api/events/search filtra eventos por filtros", %{conn: conn} do
    key = Factory.insert(:nostr_key)
    Factory.insert(:nostr_event, kind: 1, key: key)
    Factory.insert(:nostr_event, kind: 2, key: key)

    conn = get(conn, Routes.nostr_event_path(conn, :search), %{"filters" => [%{"kinds" => [1]}]})
    assert json_response(conn, 200)["events"] |> length() == 1
  end

  test "DELETE /api/events/:id deleta um evento substituível", %{conn: conn} do
    event = Factory.insert(:nostr_event, kind: 1)
    conn = delete(conn, Routes.nostr_event_path(conn, :delete, event.id))
    assert json_response(conn, 200) == %{"message" => "Evento deletado com sucesso."}
    assert DeeperServer.Repo.get(Event, event.id) == nil
  end

  test "DELETE /api/events/:id retorna erro para evento não substituível", %{conn: conn} do
    event = Factory.insert(:nostr_event, kind: 6)
    conn = delete(conn, Routes.nostr_event_path(conn, :delete, event.id))
    assert json_response(conn, 400) == %{"message" => "Este tipo de evento não pode ser deletado."}
    assert DeeperServer.Repo.get(Event, event.id) != nil
  end

  test "POST /api/events retorna erro para conteúdo muito longo", %{conn: conn} do
    key = Factory.insert(:nostr_key)

    conn =
      conn
      |> post(Routes.nostr_event_path(conn, :create), %{
        "event" => %{
          "public_key" => key.public_key,
          "created_at" => DateTime.utc_now() |> DateTime.to_unix(),
          "kind" => 1,
          "tags" => [],
          "content" => String.duplicate("A", 65536),
          "sig" => "sig..."
        },
        "recipient_public_key" => nil
      })

    assert %{"error" => "Falha ao criar evento.", "code" => "E002"} = json_response(conn, 400)
  end

end
