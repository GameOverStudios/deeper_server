defmodule DeeperServer.Nostr.MuteList do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias DeeperServer.Repo

  schema "nostr_mute_lists" do
    field :name, :string
    field :description, :string
    field :muted_pubkeys, {:array, :binary}

    timestamps()
  end

  @doc false
  def changeset(mute_list, attrs) do
    mute_list
    |> cast(attrs, [:name, :description, :muted_pubkeys])
    |> validate_required([:name, :muted_pubkeys])
  end

  @doc """
  Cria uma nova lista de silenciamento.

  ## Parâmetros

  * `attrs`: Um mapa com os atributos da lista de silenciamento.

  ## Retorno

  Retorna `{:ok, mute_list}` em caso de sucesso, ou `{:error, changeset}` em caso de erro.
  """
  @spec create_mute_list(map) :: {:ok, MuteList.t()} | {:error, Ecto.Changeset.t()}
  def create_mute_list(attrs) do
    %__MODULE__{} # Corrigido: Usar __MODULE__ para referenciar o struct atual
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Busca uma lista de silenciamento pelo ID.

  ## Parâmetros

  * `id`: O ID da lista de silenciamento.

  ## Retorno

  Retorna `{:ok, mute_list}` em caso de sucesso, ou `{:error, :not_found}` em caso de erro.
  """
  @spec get_mute_list(integer) :: {:ok, MuteList.t()} | {:error, atom}
  def get_mute_list(id) do
    case Repo.get(MuteList, id) do
      nil -> {:error, :not_found}
      mute_list -> {:ok, mute_list}
    end
  end

  @doc """
  Atualiza uma lista de silenciamento.

  ## Parâmetros

  * `id`: O ID da lista de silenciamento.
  * `attrs`: Um mapa com os atributos a serem atualizados.

  ## Retorno

  Retorna `{:ok, mute_list}` em caso de sucesso, ou `{:error, changeset}` em caso de erro.
  """
  @spec update_mute_list(integer, map) :: {:ok, MuteList.t()} | {:error, Ecto.Changeset.t()}
  def update_mute_list(id, attrs) do
    case Repo.get(MuteList, id) do
      nil -> {:error, :not_found}
      mute_list -> mute_list |> changeset(attrs) |> Repo.update()
    end
  end

  @doc """
  Deleta uma lista de silenciamento.

  ## Parâmetros

  * `id`: O ID da lista de silenciamento.

  ## Retorno

  Retorna `{:ok, mute_list}` em caso de sucesso, ou `{:error, :not_found}` em caso de erro.
  """
  @spec delete_mute_list(integer) :: {:ok, MuteList.t()} | {:error, atom}
  def delete_mute_list(id) do
    case Repo.get(MuteList, id) do
      nil -> {:error, :not_found}
      mute_list -> Repo.delete(mute_list)
    end
  end

  @doc """
  Verifica se uma chave pública está silenciada em uma lista específica.

  ## Parâmetros

  * `public_key`: A chave pública a ser verificada.
  * `mute_list_id`: O ID da lista de silenciamento.

  ## Retorno

  Retorna `true` se a chave pública estiver silenciada, ou `false` caso contrário.
  """
  @spec is_muted?(binary, integer) :: boolean
  def is_muted?(public_key, mute_list_id) do
    Repo.exists?(
      from(m in MuteList,
        where: m.id == ^mute_list_id and ^public_key in m.muted_pubkeys
      )
    )
  end
end
