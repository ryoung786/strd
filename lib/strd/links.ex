defmodule Strd.Links do
  @moduledoc """
  The Links context.
  """

  import Ecto.Query, warn: false
  alias Strd.Repo

  alias Strd.Links.Link

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

      iex> create_link(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_link(original_url) do
    create_link_with_retries(original_url, 5)
  end

  def create_link(original_url, short_url) do
    %Link{}
    |> Link.changeset(%{original: original_url, short: short_url})
    |> Repo.insert()
  end

  defp create_link_with_retries(original_url, 0) do
    cs = Link.changeset(%Link{original: original_url}, %{})
    {:error, Ecto.Changeset.add_error(cs, :original, "Unable to create a unique link")}
  end

  defp create_link_with_retries(original_url, retries) do
    try do
      %Link{}
      |> Link.changeset(%{original: original_url, short: generate_short_url()})
      |> Repo.insert()
    rescue
      Ecto.ConstraintError -> create_link_with_retries(original_url, retries - 1)
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

  # Not guaranteed to be unique!
  defp generate_short_url() do
    :crypto.strong_rand_bytes(6) |> Base.url_encode64() |> binary_part(0, 6)
  end
end
