defmodule DeeperServer.Nostr.KeyTest do
  use ExUnit.Case, async: true

  alias DeeperServer.Nostr.Key
  alias DeeperServer.Factory

  describe "create_changeset/2" do
    test "cria um changeset válido para chave" do
      attrs = %{public_key: "npub1..."}
      changeset = Key.create_changeset(%Key{}, attrs)
      assert changeset.valid?
    end

    test "cria um changeset inválido para chave com atributos faltando" do
      changeset = Key.create_changeset(%Key{}, %{})
      refute changeset.valid?
    end

    test "cria um changeset inválido para chave com chave pública duplicada" do
      Factory.insert(:nostr_key, public_key: "npub1...")
      attrs = %{public_key: "npub1..."}
      changeset = Key.create_changeset(%Key{}, attrs)
      refute changeset.valid?
    end
  end
end