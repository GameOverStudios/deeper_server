defmodule DeeperServer.Nostr.MnemonicKeyDerivation do
  @moduledoc """
  Implementação do NIP-06: Basic key derivation from mnemonic seed phrase.
  """

  @spec generate_keypair(String.t()) :: {:ok, %{private_key: binary, public_key: binary}} | {:error, atom}
  def generate_keypair(mnemonic) do
    case Nostr.Mnemonic.to_seed(mnemonic) do
      {:ok, seed} ->
        private_key = :crypto.hash(:sha256, seed)
        public_key = Nostr.get_public_key_from_private_key(private_key)
        {:ok, %{private_key: private_key, public_key: public_key}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
