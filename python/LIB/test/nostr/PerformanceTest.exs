defmodule DeeperServer.Nostr.PerformanceTest do
  use ExUnit.Case, async: true

  alias DeeperServer.Nostr.EndToEndEncryption

  test "compara performance de criptografia" do
    content = "Mensagem secreta"
    sender_private_key = <<1::256>>
    recipient_public_key = "npub1..."

    Benchee.run(
      %{
        "EndToEndEncryption.encrypt_content" => fn -> EndToEndEncryption.encrypt_content(content, sender_private_key, recipient_public_key) end,
        "OutroMétodoDeCriptografia" => fn -> outro_metodo_de_criptografia(content, sender_private_key, recipient_public_key) end
      },
      time: 5
    )
  end
end
