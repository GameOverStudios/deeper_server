defmodule DeeperServer.Nostr.RelayMetadataTest do
  use ExUnit.Case, async: true

  alias DeeperServer.Nostr.RelayMetadata

  describe "get_relay_information/1" do
    test "obtém informações do relay com sucesso" do
      relay_url = "wss://relay.damus.io"
      {:ok, relay_info} = RelayMetadata.get_relay_information(relay_url)

      assert relay_info["name"]
      assert relay_info["description"]
      assert relay_info["pubkey"]
      assert relay_info["contact"]
      assert relay_info["supported_nips"]
      assert relay_info["software"]
      assert relay_info["version"]
    end

    test "retorna erro para URL inválida" do
      relay_url = "ws://relay-invalido.com"
      assert {:error, _} = RelayMetadata.get_relay_information(relay_url)
    end
  end
end
