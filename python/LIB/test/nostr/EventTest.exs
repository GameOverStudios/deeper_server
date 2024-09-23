defmodule DeeperServer.Nostr.EventTest do
  use ExUnit.Case, async: true

  alias DeeperServer.Nostr.Event
  alias DeeperServer.Nostr.Key
  alias DeeperServer.Factory

  describe "create_changeset/2" do
    test "cria um changeset válido para evento" do
      key = Factory.insert(:nostr_key)
      attrs = %{
        public_key: key.public_key,
        created_at: DateTime.utc_now(),
        kind: 1,
        tags: [],
        content: "Hello, Nostr!",
        sig: "sig..."
      }

      changeset = Event.create_changeset(%Event{}, attrs)
      assert changeset.valid?
    end

    test "cria um changeset inválido para evento com atributos faltando" do
      changeset = Event.create_changeset(%Event{}, %{})
      refute changeset.valid?
    end
  end

  describe "serialize/1" do
    test "serializa um evento corretamente" do
      key = Factory.insert(:nostr_key)
      event = Factory.build(:nostr_event, key: key)

      serialized = Event.serialize(event)

      assert serialized == %{
               id: event.id,
               pubkey: key.public_key,
               created_at: DateTime.to_unix(event.created_at),
               kind: event.kind,
               tags: event.tags,
               content: event.content,
               sig: event.sig
             }
    end
  end

  describe "verify/2" do
    test "verifica a assinatura de um evento corretamente" do
      key = Factory.insert(:nostr_key)
      event = Factory.build(:nostr_event, key: key) |> Event.sign(key.private_key)

      assert Event.verify(event, key.public_key)
    end

    test "retorna falso para evento com assinatura inválida" do
      key = Factory.insert(:nostr_key)
      event = Factory.build(:nostr_event, key: key, sig: <<0::256>>)

      refute Event.verify(event, key.public_key)
    end
  end

  describe "match_filters?/2" do
    test "verifica se um evento corresponde aos filtros" do
      event = %{
        "id" => "id1",
        "kind" => 1,
        "pubkey" => "npub1..."
      }

      assert Event.match_filters?(event, [%{"ids" => ["id1"]}])
      assert Event.match_filters?(event, [%{"kinds" => [1]}])
      assert Event.match_filters?(event, [%{"authors" => ["npub1..."]}])
      assert Event.match_filters?(event, [%{"ids" => ["id1"], "kinds" => [1]}])
      refute Event.match_filters?(event, [%{"ids" => ["id2"]}])
    end
  end

  describe "extract_mentions/1" do
    test "extrai menções de um conteúdo de evento" do
      content = "Olá @npub1abc123, como vai você? E você, @npub456def789?"
      mentions = Event.extract_mentions(content)
      assert mentions == [
               <<208, 129, 136, 179, 1, 170, 188, 189, 129, 191, 170, 171, 188, 169, 129, 179, 1, 49, 50, 51>>,
               <<208, 129, 136, 179, 4, 53, 54, 100, 101, 102, 55, 56, 57>>
             ]
    end
  end

  describe "get_d_tag/1" do
    test "retorna a tag 'd' se presente" do
      tags = [{"d", ["minha_tag"]}, {"e", ["evento_id"]}]
      assert Event.get_d_tag(tags) == "minha_tag"
    end

    test "retorna nil se a tag 'd' não estiver presente" do
      tags = [{"e", ["evento_id"]}]
      assert Event.get_d_tag(tags) == nil
    end
  end

  describe "is_replaceable?/1" do
    test "retorna true para eventos substituíveis" do
      Enum.each([0, 1, 2, 3, 4, 5, 7, 40, 41, 42], fn kind ->
        event = Factory.build(:nostr_event, kind: kind)
        assert Event.is_replaceable?(event)
      end)
    end

    test "retorna false para eventos não substituíveis" do
      event = Factory.build(:nostr_event, kind: 6)
      refute Event.is_replaceable?(event)
    end
  end

  describe "is_parameterized_replaceable?/1" do
    test "retorna true para eventos parametrizados substituíveis" do
      Enum.each([10000, 10001, 10002], fn kind ->
        event = Factory.build(:nostr_event, kind: kind)
        assert Event.is_parameterized_replaceable?(event)
      end)
    end

    test "retorna false para eventos não parametrizados substituíveis" do
      event = Factory.build(:nostr_event, kind: 1)
      refute Event.is_parameterized_replaceable?(event)
    end
  end

  describe "apply_event_count_expiration/2" do
    test "adiciona o campo expiration_event_count ao evento" do
      event = %{"kind" => 1, "content" => "Teste"}
      event_count = 100
      updated_event = Event.apply_event_count_expiration(event, event_count)
      assert updated_event["expiration_event_count"] == event_count
    end
  end

  test "cria um changeset inválido para evento com conteúdo muito longo" do
    key = Factory.insert(:nostr_key)
    attrs = %{
      public_key: key.public_key,
      created_at: DateTime.utc_now(),
      kind: 1,
      tags: [],
      content: String.duplicate("A", 65536),
      sig: "sig..."
    }

    changeset = Event.create_changeset(%Event{}, attrs)
    refute changeset.valid?
    assert changeset.errors[:content] != []
  end

  test "verifica se um evento corresponde aos filtros" do
    # Define um evento de teste
    event = %{
      "id" => "id1",
      "kind" => 1,
      "pubkey" => "npub1..."
    }

    # Verifica a correspondência do evento com diferentes filtros
    assert Event.match_filters?(event, [%{"ids" => ["id1"]}])
    assert Event.match_filters?(event, [%{"kinds" => [1]}])
    assert Event.match_filters?(event, [%{"authors" => ["npub1..."]}])
    assert Event.match_filters?(event, [%{"ids" => ["id1"], "kinds" => [1]}])
    refute Event.match_filters?(event, [%{"ids" => ["id2"]}])
  end

end
