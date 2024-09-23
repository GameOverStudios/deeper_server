defmodule DeeperServer.Nostr.EndToEndEncryption do
  @moduledoc """
  Implementação do NIP-09: Criptografia de Ponta a Ponta.
  """

  alias DeeperServer.Nostr.Event
  alias DeeperServer.Nostr.Key

  @spec encrypt_content(String.t(), binary, binary) :: String.t()
  def encrypt_content(content, sender_private_key, recipient_public_key) do
    shared_secret = Nostr.generate_shared_secret(sender_private_key, recipient_public_key)
    ciphertext = Nostr.encrypt(content, shared_secret)
    Base.encode64(ciphertext)
  end

  @spec decrypt_content(String.t(), binary, binary) :: String.t()
  def decrypt_content(ciphertext, recipient_private_key, sender_public_key) do
    shared_secret = Nostr.generate_shared_secret(recipient_private_key, sender_public_key)
    ciphertext = Base.decode64!(ciphertext)
    Nostr.decrypt(ciphertext, shared_secret)
  end

  @spec create_encrypted_event(integer, list(Event.tag), String.t(), binary, binary) :: map
  def create_encrypted_event(kind, tags, content, sender_private_key, recipient_public_key) do
    encrypted_content = encrypt_content(content, sender_private_key, recipient_public_key)
    Event.build(kind, tags, encrypted_content, sender_private_key)
  end
end
