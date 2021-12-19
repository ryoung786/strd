defmodule Strd.Links do
  @moduledoc """
  The Links context.
  """

  import Ecto.Query, warn: false

  alias Strd.Repo
  alias Strd.Links.Link

  require Logger

  @doc """
  Returns the list of links.

  ## Examples

      iex> list_links()
      [%Link{}, ...]

  """
  def list_links do
    Repo.all(Link)
  end

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
    Logger.error("Unable to generate a unique short link", %{original: original_url})

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
      # We could make this more explicit and check that the error is a unieque
      # constraint error on the short field, but realistically it won't
      # hurt to go ahead and retry them all
      {:error, _changeset} -> create_link_with_retries(original_url, retries - 1)
      {:ok, link} -> {:ok, link}
    end
  end

  @doc """
  Updates a link.

  ## Examples

      iex> update_link(link, %{field: new_value})
      {:ok, %Link{}}

      iex> update_link(link, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_link(%Link{} = link, attrs) do
    link
    |> Link.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a link.

  ## Examples

      iex> delete_link(link)
      {:ok, %Link{}}

      iex> delete_link(link)
      {:error, %Ecto.Changeset{}}

  """
  def delete_link(%Link{} = link) do
    Repo.delete(link)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking link changes.

  ## Examples

      iex> change_link(link)
      %Ecto.Changeset{data: %Link{}}

  """
  def change_link(%Link{} = link, attrs \\ %{}) do
    Link.changeset(link, attrs)
  end

  defp generate_short_url() do
    # Not guaranteed to be unique!  This just generates a random
    # cryptographically secure string 6 characters long
    :crypto.strong_rand_bytes(6) |> Base.url_encode64() |> binary_part(0, 6)
  end
end
