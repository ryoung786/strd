defmodule Strd.Links do
  @moduledoc """
  The Links context.
  """

  import Ecto.Query, warn: false
  alias Strd.Repo
  alias Strd.Links.Link
  alias Strd.Accounts.User
  require Logger

  @doc """
  Gets a single link.

  Raises `Ecto.NoResultsError` if the Link does not exist.

  ## Examples

      iex> get_link!(123)
      %Link{}

      iex> get_link!(456)
      ** (Ecto.NoResultsError)

  """
  def get_link!(id), do: Repo.get!(Link, id)

  @doc """
  Gets a single link.

  Raises `Ecto.NoResultsError` if the Link does not exist.

  ## Examples

      iex> get_by_short_url!("aY3QPy")
      %Link{}

      iex> get_by_short_url!("none")
      ** (Ecto.NoResultsError)

  """
  def get_by_short_url!(short_url), do: Repo.get_by!(Link, short: short_url)

  def get_by_user(%Strd.Accounts.User{} = user), do: Repo.all(Ecto.assoc(user, :links))

  @doc """
  Creates a link.

  ## Examples

      iex> create_link(url)
      {:ok, %Link{}}

      iex> create_link(malformed_url)
      {:error, %Ecto.Changeset{}}

  """
  def create_link(original_url, nil = _user) do
    %Link{}
    |> Link.changeset(%{original: original_url, short: generate_short_url()})
    |> create_link_with_retries(5)
  end

  def create_link(original_url, %User{id: user_id}) do
    %Link{}
    |> Link.changeset(%{original: original_url, short: generate_short_url(), user_id: user_id})
    |> create_link_with_retries(5)
  end

  def create_link(original_url, short_url, nil = _user) do
    %Link{}
    |> Link.changeset(%{original: original_url, short: short_url})
    |> Repo.insert()
  end

  def create_link(original_url, short_url, %User{id: user_id}) do
    %Link{}
    |> Link.changeset(%{original: original_url, short: short_url, user_id: user_id})
    |> Repo.insert()
  end

  defp create_link_with_retries(changeset, 0) do
    # Recursion base case.  If we hit this, then we've generated 5 short urls,
    # and all of them have already been used.  In production, this is the kind of
    # thing we should alert on.
    Logger.error("Unable to generate a unique short link", %{
      original_url: Ecto.Changeset.get_field(changeset, :original_url)
    })

    # use new_changeset to avoid validation
    cs =
      changeset
      |> Ecto.Changeset.add_error(:original, "Unable to generate a unique link")
      |> Map.put(:action, :insert)

    {:error, cs}
  end

  defp create_link_with_retries(changeset, retries) do
    changeset
    |> Link.changeset(%{short: generate_short_url()})
    |> Repo.insert()
    |> case do
      {:error, error_changeset} ->
        # Only retry with a newly generated short url if the error
        # is that we violated the unique constraint
        if short_url_taken?(error_changeset),
          do: create_link_with_retries(changeset, retries - 1),
          else: {:error, error_changeset}

      {:ok, link} ->
        {:ok, link}
    end
  end

  @doc """
  Increments the view_count of a given Link by num
  """
  def increase_view_count(short_url, num \\ 1) when short_url != nil do
    from(l in Link, where: l.short == ^short_url, select: l.view_count)
    |> Repo.update_all(inc: [view_count: num])
  end

  defp generate_short_url() do
    # Not guaranteed to be unique!  This just generates a random
    # cryptographically secure string 6 characters long
    :crypto.strong_rand_bytes(6) |> Base.url_encode64() |> binary_part(0, 6)
  end

  defp short_url_taken?({:short, {_, [constraint: :unique, constraint_name: _]}}), do: true
  defp short_url_taken?(_), do: false
end
