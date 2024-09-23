defmodule DeeperServer.Nostr.CommandLineInterface do
  @moduledoc """
  Implementação do NIP-20: Command Line Interface.

  Esta CLI permite interagir com o Deeper Server através de comandos simples.
  """

  alias DeeperServer.Nostr.Event
  alias DeeperServer.Nostr.Key
  alias DeeperServer.Nostr.Client
  alias DeeperServer.Nostr.MnemonicKeyDerivation
  alias DeeperServer.Nostr.Bech32Encoding
  alias DeeperServer.Nostr.ProofOfWork
  alias DeeperServer.Nostr.DirectMessage
  alias DeeperServer.Nostr.EndToEndEncryption
  alias DeeperServer.Nostr.DelegatedEventSigning
  alias DeeperServer.Nostr.EventExpiration
  alias DeeperServer.Nostr.FileMetadata
  alias DeeperServer.Nostr.GenericTagQueries
  alias DeeperServer.Nostr.LongFormContent
  alias DeeperServer.Nostr.RelayMetadata
  alias DeeperServer.Repo

  def start_cli do
    IO.puts("Deeper Server CLI iniciado.")

    # Loop para receber comandos do usuário
    receive do
      command ->
        handle_command(command)
    end
  end

  @spec handle_command(String.t()) :: :ok
  defp handle_command(command) do
    case String.split(command, " ") do
      ["exit"] ->
        IO.puts("Encerrando Deeper Server CLI.")
        :ok

      ["help"] ->
        show_help()
        handle_command(receive_command())

      # Gerenciamento de Chaves
      ["create-key"] ->
        create_key()
        handle_command(receive_command())

      ["list-keys"] ->
        list_keys()
        handle_command(receive_command())

      # Publicação de Eventos
      ["publish-event", kind, tags, content, public_key] ->
        publish_event(kind, tags, content, public_key)
        handle_command(receive_command())

      # Assinatura de Eventos
      ["subscribe", filters] ->
        subscribe(filters)
        handle_command(receive_command())

      # Listagem de Eventos
      ["list-events"] ->
        list_events()
        handle_command(receive_command())

      # Gerenciamento de Relays
      ["list-relays"] ->
        list_relays()
        handle_command(receive_command())

      ["get-relay-info", relay_url] ->
        get_relay_info(relay_url)
        handle_command(receive_command())

      # Mensagens Diretas
      ["send-dm", recipient_public_key, message, sender_private_key] ->
        send_dm(recipient_public_key, message, sender_private_key)
        handle_command(receive_command())

      # Criptografia de Ponta a Ponta
      ["encrypt", content, sender_private_key, recipient_public_key] ->
        encrypt(content, sender_private_key, recipient_public_key)
        handle_command(receive_command())

      ["decrypt", ciphertext, recipient_private_key, sender_public_key] ->
        decrypt(ciphertext, recipient_private_key, sender_public_key)
        handle_command(receive_command())

      # Assinatura Delegada
      ["create-delegated-event", kind, tags, content, delegator_private_key, delegatee_public_key, conditions] ->
        create_delegated_event(kind, tags, content, delegator_private_key, delegatee_public_key, conditions)
        handle_command(receive_command())

      # Expiração de Eventos
      ["create-event-with-expiration", kind, tags, content, private_key, expiration_datetime] ->
        create_event_with_expiration(kind, tags, content, private_key, expiration_datetime)
        handle_command(receive_command())

      # Metadados de Arquivos
      ["create-file-metadata-event", file_metadata, private_key] ->
        create_file_metadata_event(file_metadata, private_key)
        handle_command(receive_command())

      # Queries Genéricas de Tags
      ["filter-events", events, filters] ->
        filter_events(events, filters)
        handle_command(receive_command())

      # Conteúdo de Formato Longo
      ["create-long-form-event", content, private_key] ->
        create_long_form_event(content, private_key)
        handle_command(receive_command())

      # Proof of Work
      ["calculate-pow", data, difficulty] ->
        calculate_pow(data, difficulty)
        handle_command(receive_command())

      ["verify-pow", data, nonce, difficulty] ->
        verify_pow(data, nonce, difficulty)
        handle_command(receive_command())

      _ ->
        IO.puts("Comando inválido: #{command}")
        handle_command(receive_command())
    end
  end

  defp receive_command do
    IO.gets("> ") |> String.trim()
  end

  defp show_help do
    IO.puts("Comandos disponíveis:")
    IO.puts("  exit - Encerra a CLI.")
    IO.puts("  help - Mostra a lista de comandos.")

    # Gerenciamento de Chaves
    IO.puts("  create-key - Cria uma nova chave Nostr.")
    IO.puts("  list-keys - Lista todas as chaves no sistema.")

    # Publicação de Eventos
    IO.puts("  publish-event [kind] [tags] [content] [public_key] - Publica um novo evento.")

    # Assinatura de Eventos
    IO.puts("  subscribe [filters] - Assina eventos com filtros.")

    # Listagem de Eventos
    IO.puts("  list-events - Lista todos os eventos no sistema.")

    # Gerenciamento de Relays
    IO.puts("  list-relays - Lista todos os relays configurados.")
    IO.puts("  get-relay-info [relay_url] - Busca informações de um relay.")

    # Mensagens Diretas
    IO.puts("  send-dm [recipient_public_key] [message] [sender_private_key] - Envia uma mensagem direta criptografada.")

    # Criptografia de Ponta a Ponta
    IO.puts("  encrypt [content] [sender_private_key] [recipient_public_key] - Criptografa conteúdo.")
    IO.puts("  decrypt [ciphertext] [recipient_private_key] [sender_public_key] - Descriptografa conteúdo.")

    # Assinatura Delegada
    IO.puts("  create-delegated-event [kind] [tags] [content] [delegator_private_key] [delegatee_public_key] [conditions] - Cria um evento delegado.")

    # Expiração de Eventos
    IO.puts("  create-event-with-expiration [kind] [tags] [content] [private_key] [expiration_datetime] - Cria um evento com expiração.")

    # Metadados de Arquivos
    IO.puts("  create-file-metadata-event [file_metadata] [private_key] - Cria um evento com metadados de arquivo.")

    # Queries Genéricas de Tags
    IO.puts("  filter-events [events] [filters] - Filtra eventos com base em tags.")

    # Conteúdo de Formato Longo
    IO.puts("  create-long-form-event [content] [private_key] - Cria um evento de conteúdo de formato longo.")

    # Proof of Work
    IO.puts("  calculate-pow [data] [difficulty] - Calcula o Proof of Work.")
    IO.puts("  verify-pow [data] [nonce] [difficulty] - Verifica o Proof of Work.")
  end

  defp create_key do
    IO.puts("Insira uma frase mnemônica:")
    mnemonic = receive_command()

    case MnemonicKeyDerivation.generate_keypair(mnemonic) do
      {:ok, %{private_key: private_key, public_key: public_key}} ->
        IO.puts("Chave criada com sucesso!")
        IO.puts("Chave privada: #{Base.encode16(private_key, case: :lower)}")
        IO.puts("Chave pública: #{public_key}")

        Repo.insert!(Key, public_key: public_key)
        :ok

      {:error, reason} ->
        IO.puts("Falha ao criar chave: #{reason}")
        :ok
    end
  end

  defp list_keys do
    IO.puts("Chaves:")

    keys = Repo.all(Key)

    if Enum.empty?(keys) do
      IO.puts("Nenhuma chave encontrada.")
    else
      Enum.each(keys, fn key ->
        IO.puts("Chave pública: #{key.public_key}")
        IO.puts("-" * 10)
      end)
    end
  end

  defp publish_event(kind, tags, content, public_key) do
    IO.puts("Publicando evento...")

    # Valida a chave pública
    case Repo.get_by(Key, public_key: public_key) do
      nil ->
        IO.puts("Chave pública não encontrada.")
        :ok

      key ->
        kind = String.to_integer(kind)
        tags =
          tags
          |> String.split(",")
          |> Enum.map(fn tag ->
            String.split(tag, ":")
            |> Enum.map(&String.trim/1)
            |> List.to_tuple()
          end)
        content = String.trim(content)

        # Cria o evento
        event =
          Event.build(kind, tags, content, key.private_key)
          |> Event.sign(key.private_key)

        # Publica o evento para os relays
        Enum.each(Application.get_env(:deeper_server, :nostr)[:relays], fn relay_url ->
          case Client.connect(relay_url) do
            {:ok, relay_pid} ->
              Client.publish_event(relay_pid, event)
              :ok

            {:error, reason} ->
              IO.puts("Falha ao conectar ao relay #{relay_url}: #{reason}")
              :ok
          end
        end)

        IO.puts("Evento publicado com sucesso!")
        :ok
    end
  end

  defp subscribe(filters) do
    IO.puts("Assinando eventos...")

    filters =
      filters
      |> String.split(",")
      |> Enum.map(fn filter ->
        String.split(filter, ":")
        |> Enum.map(&String.trim/1)
        |> List.to_tuple()
        |> then(fn {k, v} ->
          {k, String.split(v, ",") |> Enum.map(&String.trim/1)}
        end)
        |> then(fn {k, v} ->
          case k do
            "ids" -> %{k => v |> Enum.map(&Event.decode_id/1)}
            "kinds" -> %{k => v |> Enum.map(&String.to_integer/1)}
            "authors" -> %{k => v |> Enum.map(&Base.decode16!/1)}
            _ -> %{k => v}
          end
        end)
      end) # <- Closing this Enum.map pipeline

    # Itera pelos relays para assinar eventos
    Enum.each(Application.get_env(:deeper_server, :nostr)[:relays], fn relay_url ->
      case Client.connect(relay_url) do
        {:ok, relay_pid} ->
          Client.subscribe_to_events(relay_pid, filters)
          :ok

        {:error, reason} ->
          IO.puts("Falha ao conectar ao relay #{relay_url}: #{reason}")
          :ok
      end
    end)

    IO.puts("Assinatura iniciada. Aguardando eventos.")
    :ok
  end

  defp list_events do
    IO.puts("Eventos:")

    events = Repo.all(Event)

    if Enum.empty?(events) do
      IO.puts("Nenhum evento encontrado.")
    else
      Enum.each(events, fn event ->
        IO.puts("ID: #{Event.encode_id(event.id)}")
        IO.puts("Kind: #{event.kind}")
        IO.puts("Tags: #{inspect(event.tags)}")
        IO.puts("Content: #{event.content}")
        IO.puts("-" * 10)
      end)
    end
  end

  defp list_relays do
    IO.puts("Relays:")

    relays = Application.get_env(:deeper_server, :nostr)[:relays]

    if Enum.empty?(relays) do
      IO.puts("Nenhum relay configurado.")
    else
      Enum.each(relays, fn relay ->
        IO.puts("URL: #{relay}")
        IO.puts("-" * 10)
      end)
    end
  end

  defp get_relay_info(relay_url) do
    IO.puts("Buscando informações do relay...")

    case RelayMetadata.get_relay_information(relay_url) do
      {:ok, relay_info} ->
        IO.puts("Informações do relay:")
        IO.inspect(relay_info)
        :ok

      {:error, reason} ->
        IO.puts("Falha ao obter informações do relay: #{reason}")
        :ok
    end
  end

  defp send_dm(recipient_public_key, message, sender_private_key) do
    IO.puts("Enviando mensagem direta...")

    case DirectMessage.create_encrypted_dm_event(message, sender_private_key, recipient_public_key) do
      {:ok, event} ->
        # Publica o evento para os relays
        Enum.each(Application.get_env(:deeper_server, :nostr)[:relays], fn relay_url ->
          case Client.connect(relay_url) do
            {:ok, relay_pid} ->
              Client.publish_event(relay_pid, event)
              :ok

            {:error, reason} ->
              IO.puts("Falha ao conectar ao relay #{relay_url}: #{reason}")
              :ok
          end
        end)

        IO.puts("Mensagem direta enviada com sucesso!")
        :ok

      {:error, reason} ->
        IO.puts("Falha ao enviar mensagem direta: #{reason}")
        :ok
    end
  end

  defp encrypt(content, sender_private_key, recipient_public_key) do
    IO.puts("Criptografando conteúdo...")

    ciphertext = EndToEndEncryption.encrypt_content(content, sender_private_key, recipient_public_key)
    IO.puts("Ciphertext: #{Base.encode64(ciphertext)}")
    :ok
  end

  defp decrypt(ciphertext, recipient_private_key, sender_public_key) do
    IO.puts("Descriptografando conteúdo...")

    ciphertext = Base.decode64!(ciphertext)
    plaintext = EndToEndEncryption.decrypt_content(ciphertext, recipient_private_key, sender_public_key)
    IO.puts("Plaintext: #{plaintext}")
    :ok
  end

  defp create_delegated_event(kind, tags, content, delegator_private_key, delegatee_public_key, conditions) do
    IO.puts("Criando evento delegado...")

    case DelegatedEventSigning.create_delegated_event(kind, tags, content, delegator_private_key, delegatee_public_key, conditions) do
      {:ok, %{delegation_token: delegation_token, event: event}} ->
        # Publica o evento para os relays
        Enum.each(Application.get_env(:deeper_server, :nostr)[:relays], fn relay_url ->
          case Client.connect(relay_url) do
            {:ok, relay_pid} ->
              Client.publish_event(relay_pid, delegation_token)
              Client.publish_event(relay_pid, event)
              :ok

            {:error, reason} ->
              IO.puts("Falha ao conectar ao relay #{relay_url}: #{reason}")
              :ok
          end
        end)

        IO.puts("Evento delegado criado e publicado!")
        :ok

      {:error, reason} ->
        IO.puts("Falha ao criar evento delegado: #{reason}")
        :ok
    end
  end

  defp create_event_with_expiration(kind, tags, content, private_key, expiration_datetime) do
    IO.puts("Criando evento com expiração...")

    case EventExpiration.create_event_with_expiration(kind, tags, content, private_key, expiration_datetime) do
      {:ok, event} ->
        # Publica o evento para os relays
        Enum.each(Application.get_env(:deeper_server, :nostr)[:relays], fn relay_url ->
          case Client.connect(relay_url) do
            {:ok, relay_pid} ->
              Client.publish_event(relay_pid, event)
              :ok

            {:error, reason} ->
              IO.puts("Falha ao conectar ao relay #{relay_url}: #{reason}")
              :ok
          end
        end)

        IO.puts("Evento com expiração criado e publicado!")
        :ok

      {:error, reason} ->
        IO.puts("Falha ao criar evento com expiração: #{reason}")
        :ok
    end
  end

  defp create_file_metadata_event(file_metadata, private_key) do
    IO.puts("Criando evento com metadados de arquivo...")

    case FileMetadata.create_file_metadata_event(file_metadata, private_key) do
      {:ok, event} ->
        # Publica o evento para os relays
        Enum.each(Application.get_env(:deeper_server, :nostr)[:relays], fn relay_url ->
          case Client.connect(relay_url) do
            {:ok, relay_pid} ->
              Client.publish_event(relay_pid, event)
              :ok

            {:error, reason} ->
              IO.puts("Falha ao conectar ao relay #{relay_url}: #{reason}")
              :ok
          end
        end)

        IO.puts("Evento com metadados de arquivo criado e publicado!")
        :ok

      {:error, reason} ->
        IO.puts("Falha ao criar evento com metadados de arquivo: #{reason}")
        :ok
    end
  end

  defp filter_events(events, filters) do
    IO.puts("Filtrando eventos...")

    # Processa os eventos e filtros
    # ...

    IO.puts("Eventos filtrados:")
    # ...

    :ok
  end

  defp create_long_form_event(content, private_key) do
    IO.puts("Criando evento de conteúdo de formato longo...")

    case LongFormContent.create_long_form_event(content, private_key) do
      {:ok, event} ->
        # Publica o evento para os relays
        Enum.each(Application.get_env(:deeper_server, :nostr)[:relays], fn relay_url ->
          case Client.connect(relay_url) do
            {:ok, relay_pid} ->
              Client.publish_event(relay_pid, event)
              :ok

            {:error, reason} ->
              IO.puts("Falha ao conectar ao relay #{relay_url}: #{reason}")
              :ok
          end
        end)

        IO.puts("Evento de conteúdo de formato longo criado e publicado!")
        :ok

      {:error, reason} ->
        IO.puts("Falha ao criar evento de conteúdo de formato longo: #{reason}")
        :ok
    end
  end

  defp calculate_pow(data, difficulty) do
    IO.puts("Calculando Proof of Work...")

    nonce = ProofOfWork.calculate_pow(data, String.to_integer(difficulty))
    IO.puts("Nonce: #{nonce}")
    :ok
  end

  defp verify_pow(data, nonce, difficulty) do
    IO.puts("Verificando Proof of Work...")

    result = ProofOfWork.verify_pow(data, String.to_integer(nonce), String.to_integer(difficulty))
    IO.puts("Resultado: #{result}")
    :ok
  end
end
