defmodule Mailcalf.Config do
  alias Mailcalf.Config.OAuth
  alias Mailcalf.Config.ExtraConfig
  alias Mailcalf.Config.Tls
  alias Mailcalf.Config.Imap
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :postmaster_address, :string
    field :hostname, :string
    field :storage_dir, :string
    embeds_one :imap, Imap
    embeds_one :tls, Tls
    embeds_one :oauth, OAuth
    embeds_one :extra, ExtraConfig
  end

  defmodule Imap do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field :enable, :boolean
      field :enable_sieve, :boolean
      field :enable_managesieve, :boolean
      field :listeners, {:array, :string}
    end

    def changeset(data, changes) do
      data
      |> cast(changes, [:enable, :enable_sieve, :enable_managesieve, :listeners])
      |> validate_subset(:listeners, ["imap", "imaps"])
    end
  end

  defmodule Tls do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field :private_key, :string
      field :certificate, :string
    end

    def changeset(data, changes) do
      data
      |> cast(changes, [:private_key, :certificate])
    end
  end

  defmodule OAuth do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field :debug, :boolean
      field :grant_url, :string
      field :introspection_url, :string
      field :client_id, :string
      field :client_secret, :string
      field :username_attribute, :string
    end

    def changeset(data, changes) do
      url = ~r"http(s)://.*"
      data
      |> cast(changes, [:debug, :grant_url, :introspection_url, :client_id, :client_secret, :username_attribute])
      |> validate_required([:grant_url, :introspection_url, :client_id, :client_secret, :username_attribute])
      |> validate_format(:grant_url, url, [message: "not a valid url"])
      |> validate_format(:introspection_url, url, [message: "not a valid url"])
    end
  end

  defmodule ExtraConfig do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field :dovecot, :string
    end

    def changeset(data, changes) do
      data
      |> cast(changes, [:dovecot])
    end
  end

  @doc """
  Get validated configuration from the applications environment
  """
  def get() do
    changeset = %__MODULE__{}
    |> cast(Application.get_env(:mailcalf, :mailserver, %{}), [:postmaster_address, :hostname, :storage_dir])
    |> validate_required([:postmaster_address, :hostname, :storage_dir])
    |> validate_format(:postmaster_address, ~r".*@.*", [message: "not a valid email address"])
    |> cast_embed(:imap, [:required])
    |> cast_embed(:tls)
    |> cast_embed(:oauth, [:required])
    |> cast_embed(:extra, [:required])

    case changeset.valid? do
      true -> apply_changes(changeset)
      false -> cond do
        changeset.errors != [] -> raise "Config is not valid: #{inspect(changeset.errors)}"
        !changeset.changes.imap.valid? -> raise "Config.imap is not valid: #{inspect(changeset.changes.imap.errors)}"
        !changeset.changes.oauth.valid? -> raise "Config.oauth is not valid: #{inspect(changeset.changes.oauth.errors)}"
        !changeset.changes.extra.valid? -> raise "Config.extra is not valid: #{inspect(changeset.changes.extra.errors)}"
      end
    end
  end
end
