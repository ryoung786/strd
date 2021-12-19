defmodule StrdWeb.LinkController do
  use StrdWeb, :controller
  import Ecto.Query, warn: false
  import Ecto.Changeset

  alias __MODULE__.UserInput
  alias Strd.Links

  def index(conn, _params) do
    render(conn, "index.html", changeset: UserInput.changeset())
  end

  def show(conn, %{"short_url" => short_url}) do
    link = Links.get_by_short_url!(short_url)
    render(conn, "show.html", link: link)
  end

  def create(conn, %{"link" => params}) do
    # by normalizing our user input, we can ensure our Context
    # has an explicit contract boundary
    case StrdWeb.LinkController.UserInput.normalize(params) do
      {:ok, %{original: original, short: short}} -> create_link(conn, original, short)
      {:ok, %{original: original}} -> create_link(conn, original)
      {:error, changeset} -> render(conn, "index.html", changeset: changeset)
    end
  end

  defp create_link(conn, original, short) do
    Links.create_link(original, short) |> handle_create_link(conn)
  end

  defp create_link(conn, original) do
    Links.create_link(original) |> handle_create_link(conn)
  end

  defp handle_create_link({:ok, link}, conn) do
    conn
    |> put_flash(:info, "Link created successfully.")
    |> redirect(to: Routes.link_path(conn, :show, link))
  end

  defp handle_create_link({:error, %Ecto.Changeset{} = changeset}, conn) do
    render(conn, "index.html", changeset: changeset)
  end
end

defmodule StrdWeb.LinkController.UserInput do
  import Ecto.Changeset

  @types %{original: :string, short: :string}

  def changeset(params \\ %{}) do
    {%{}, @types}
    |> cast(params, Map.keys(@types))
  end

  @doc """
  Change our param map keys from strings to keywords and sanitize the user input
  """
  def normalize(params) do
    changeset(params)
    |> update_change(:original, &String.trim/1)
    |> update_change(:short, &String.trim/1)
    |> update_change(:short, &URI.encode/1)
    |> validate_length(:original, count: :bytes, max: 512)
    |> validate_format(:short, ~r/^\w+$/)
    |> validate_length(:short, max: 256)
    |> apply_action(:insert)
  end
end
