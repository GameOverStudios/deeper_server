defmodule DeeperServer.Nostr.MuteListTest do
  use ExUnit.Case, async: true

  alias DeeperServer.Nostr.MuteList
  alias DeeperServer.Factory

  describe "is_muted?/2" do
    test "verifica se uma chave pública está em uma lista de silenciamento" do
      mute_list = Factory.insert(:nostr_mute_list, muted_pubkeys: ["npub1..."])
      assert MuteList.is_muted?("npub1...", mute_list.id)
      refute MuteList.is_muted?("npub2...", mute_list.id)
    end
  end

  # Adicione testes para as outras funções do NIP-69: create_mute_list, get_mute_list, update_mute_list, delete_mute_list
end
