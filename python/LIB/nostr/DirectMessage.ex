defmodule DeeperServer.Nostr.DirectMessage do
  @moduledoc """
  Implementação do NIP-04: Mensagens Diretas Criptografadas.
  """

  alias DeeperServer.Nostr.Event

  @spec encrypt_message(String.t(), binary, binary) :: String.t()
  def encrypt_message(message, sender_private_key, recipient_public_key) do
    ciphertext = Nostr.encrypt(message, sender_private_key, recipient_public_key)
    Base.encode64(ciphertext)
  end

  @spec decrypt_message(String.t(), binary, binary) :: String.t()
  def decrypt_message(ciphertext, recipient_private_key, sender_public_key) do
    ciphertext = Base.decode64!(ciphertext)
    Nostr.decrypt(ciphertext, recipient_private_key, sender_public_key)
  end

  @spec create_encrypted_dm_event(String.t(), binary, binary) :: map
  def create_encrypted_dm_event(message, sender_private_key, recipient_public_key) do
    encrypted_message = encrypt_message(message, sender_private_key, recipient_public_key)

    Event.build(4, [
      {"p", [recipient_public_key]}
    ], encrypted_message, sender_private_key)
  end
end
