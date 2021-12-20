defmodule Strd.Links.Link do
  use Ecto.Schema
  import Ecto.Changeset

  schema "links" do
    field :original, :string
    field :short, :string
    field :view_count, :integer, default: 0

    timestamps()
  end

  @type t :: %__MODULE__{original: String.t(), short: String.t()}

  @doc false
  def new_changeset(link, attrs) do
    cast(link, attrs, [:original, :short, :view_count])
  end

  @doc false
  def changeset(link, attrs) do
    link
    |> cast(attrs, [:original, :short, :view_count])
    |> validate_required([:original, :short])
    |> validate_length(:short, min: 3)
    |> validate_url(:original)
    |> validate_url(:short)
    |> validate_number(:view_count, min: 0)
    |> unique_constraint(:short)
  end

  def validate_url(%Ecto.Changeset{} = link_changeset, :original) do
    link = Ecto.Changeset.get_field(link_changeset, :original)

    case URI.new(link) do
      {:ok, %{scheme: scheme, host: host}} ->
        cond do
          scheme not in ~w(http https) ->
            err_msg = "URL must begin with \"http://\" or \"https://\""
            add_error(link_changeset, :original, err_msg)

          !Regex.match?(~r/.\.../, host) ->
            # This regex ensures the host has at least one character
            # preceeding the '.', and at least 2 characters in the tld
            add_error(link_changeset, :original, "Invalid host name")

          true ->
            link_changeset
        end

      {:error, _part} ->
        add_error(link_changeset, :original, "Not a valid URL")
    end
  end

  def validate_url(%Ecto.Changeset{} = link_changeset, :short) do
    path = Ecto.Changeset.get_field(link_changeset, :short)

    if is_nil(path) do
      link_changeset
    else
      case URI.new(path) do
        {:ok, _uri} -> link_changeset
        {:error, part} -> add_error(link_changeset, :short, "Cannot use #{part} in a short link")
      end
    end
  end
end

defimpl Phoenix.Param, for: Strd.Links.Link do
  def to_param(%{short: short_url}) do
    "#{short_url}"
  end
end
