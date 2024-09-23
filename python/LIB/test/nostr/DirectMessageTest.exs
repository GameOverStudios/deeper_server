defmodule DeeperServer.Nostr.DirectMessageTest do
  use ExUnit.Case

  alias DeeperServer.Nostr.DirectMessage
  alias DeeperServer.Nostr.Key
  alias DeeperServer.Factory

  describe "create_encrypted_dm_event/3" do
    test "cria um evento de mensagem direta criptografada" do
      sender_key = Factory.insert(:nostr_key)
      recipient_key = Factory.insert(:nostr_key)

      event = DirectMessage.create_encrypted_dm_event("Mensagem secreta!", sender_key.private_key, recipient_key.public_key)

      assert event["kind"] == 4
      assert Enum.member?(event["tags"], {"p", [recipient_key.public_key]})
      assert event["content"] != "Mensagem secreta!"
    end
  end
end
