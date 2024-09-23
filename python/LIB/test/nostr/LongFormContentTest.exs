defmodule DeeperServer.Nostr.LongFormContentTest do
  use ExUnit.Case

  alias DeeperServer.Nostr.LongFormContent

  test "create_long_form_event/2 cria um evento de formato longo" do
    private_key = <<1::256>>
    content = "Este é um conteúdo de formato longo."
    event = LongFormContent.create_long_form_event(content, private_key)

    assert event.kind == 30023
    assert event.content == content
  end
end
