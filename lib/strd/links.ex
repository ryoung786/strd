defmodule Strd.Links do
  @moduledoc """
  The Links context.
  """

  import Ecto.Query, warn: false
  alias Strd.Repo
  alias Strd.Links.Link
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

  @doc """
  Creates a link.

  ## Examples

      iex> create_link(url)
      {:ok, %Link{}}

      iex> create_link(malformed_url)
      {:error, %Ecto.Changeset{}}

  """
  @spec create_link(String.t()) :: {:ok, Link.t()} | {:error, Ecto.Changeset.t()}
  def create_link(original_url) do
    create_link_with_retries(original_url, 5)
  end

  @spec create_link(String.t(), String.t()) :: {:ok, Link.t()} | {:error, Ecto.Changeset.t()}
  def create_link(original_url, short_url) do
    # When the client provides a short url, we don't need to generate one.
    # This also means we don't need to retry Link creation if it fails the
    # unique constraint check.
    %Link{}
    |> Link.changeset(%{original: original_url, short: short_url})
    |> Repo.insert()
  end

  defp create_link_with_retries(original_url, 0) do
    # Recursion base case.  If we hit this, then we've generated 5 short urls,
    # and all of them have already been used.  In production, this is the kind of
    # thing we should alert on.
    Logger.error("Unable to generate a unique short link", %{original_url: original_url})

    # use new_changeset to avoid validation
    cs =
      %Link{original: original_url}
      |> Link.new_changeset(%{})
      |> Ecto.Changeset.add_error(:original, "Unable to generate a unique link")
      |> Map.put(:action, :insert)

    {:error, cs}
  end

  defp create_link_with_retries(original_url, retries) do
    %Link{}
    |> Link.changeset(%{original: original_url, short: generate_short_url()})
    |> Repo.insert()
    |> case do
      {:error, changeset} ->
        # Only retry with a newly generated short url if the error
        # is that we violated the unique constraint
        if short_url_taken?(changeset),
          do: create_link_with_retries(original_url, retries - 1),
          else: {:error, changeset}

      {:ok, link} ->
        {:ok, link}
    end
  end

  defp generate_short_url() do
    # Not guaranteed to be unique!  This just generates a random
    # cryptographically secure string 6 characters long
    :crypto.strong_rand_bytes(6) |> Base.url_encode64() |> binary_part(0, 6)
  end

  defp short_url_taken?({:short, {_, [constraint: :unique, constraint_name: _]}}), do: true
  defp short_url_taken?(_), do: false
end
