defmodule DeeperServer.Nostr.AuthTest do
  use ExUnit.Case, async: true

  alias DeeperServer.Nostr.Auth
  alias DeeperServer.Nostr.AuthFixtures

  import Mox

  setup :verify_on_exit!

  describe "authenticate_user/2" do
    test "autentica usuário com evento válido" do
      key = AuthFixtures.key_fixture()
      event = AuthFixtures.event_fixture(key)

      expect(Event, :verify, fn ^event, ^key.public_key -> true end)

      conn = %Plug.Conn{assigns: %{current_user: nil}}
      conn = Auth.authenticate_user(conn, %{"public_key" => key.public_key, "event" => event})

      assert conn.assigns.current_user.key.public_key == key.public_key
      assert conn.status == 200
    end

    test "retorna erro para evento inválido", %{conn: conn} do
      key = AuthFixtures.key_fixture()
      invalid_event = %{}

      conn = Auth.authenticate_user(conn, %{"public_key" => key.public_key, "event" => invalid_event})

      assert conn.assigns.current_user == nil
      assert conn.status == 401
    end

    test "retorna erro para chave pública não encontrada", %{conn: conn} do
      conn = Auth.authenticate_user(conn, %{"public_key" => "npub1...", "event" => %{}})

      assert conn.assigns.current_user == nil
      assert conn.status == 401
    end

    test "loga erro para evento com assinatura inválida" do
      key = AuthFixtures.key_fixture()
      event = AuthFixtures.event_fixture(key, sig: "invalid_signature")

      expect(Event, :verify, fn ^event, ^key.public_key -> false end)

      log_message = "Falha na autenticação: :invalid_signature"

      ExUnit.CaptureLog.capture_log(fn ->
        conn = %Plug.Conn{assigns: %{current_user: nil}}
        Auth.authenticate_user(conn, %{"public_key" => key.public_key, "event" => event})
      end) =~ log_message
    end
  end
end
