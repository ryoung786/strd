defmodule StrdWeb.LinkController do
  use StrdWeb, :controller
  import Ecto.Query, warn: false
  import Ecto.Changeset

  alias __MODULE__.UserInput
  alias Strd.Links

  def index(conn, _params) do
    render(conn, "index.html", changeset: UserInput.changeset())
  end

  def mylinks_index(conn, _params) do
    %{assigns: %{current_user: user}} = conn
    render(conn, "mylinks_index.html", links: Links.get_by_user(user))
  end

  def redirect_short_url(conn, %{"short_url" => short_url}) do
    link = Links.get_by_short_url!(short_url)

    :telemetry.execute([:links, :short], %{views: 1}, %{short_url: short_url})

    redirect(conn, external: link.original)
  end

  def show(conn, %{"short_url" => short_url}) do
    link = Links.get_by_short_url!(short_url)
    render(conn, "show.html", link: link)
  end

  def create(conn, %{"link" => params}) do
    user = Map.get(conn.assigns, :current_user)

    case StrdWeb.LinkController.UserInput.normalize(params) do
      {:ok, %{original: original, short: short}} -> create_link(conn, original, short, user)
      {:ok, %{original: original}} -> create_link(conn, original, user)
      {:error, changeset} -> render(conn, "index.html", changeset: changeset)
    end
  end

  defp create_link(conn, original, short, user) do
    Links.create_link(original, short, user) |> handle_create_link(conn)
  end

  defp create_link(conn, original, user) do
    Links.create_link(original, user) |> handle_create_link(conn)
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
  alias Strd.Links.Link

  @types %{original: :string, short: :string}

  def changeset(params \\ %{}) do
    {%{}, @types}
    |> cast(params, Map.keys(@types))
  end

  @doc """
  Change our param map keys from strings to keywords and sanitize the user input
  """
  def normalize(params) do
    # by normalizing our user input, we can ensure our Context
    # has an explicit contract boundary
    #
    # I really dislike having the validation duplicated both here and in the schema,
    # but it's accomplishing 2 different tasks.  Here, we want to allow the short
    # link to be empty, whereas in the schema we need to verify it to be present.
    changeset(params)
    |> update_change(:original, &String.trim/1)
    |> update_change(:short, &String.trim/1)
    |> validate_required(:original)
    |> validate_length(:original,
      count: :bytes,
      max: 512,
      message: "Max length: %{count} characters"
    )
    |> Link.validate_url(:original)
    |> validate_format(:short, ~r/^\w+$/)
    |> validate_length(:short, max: 6, message: "Max length: %{count} characters")
    |> apply_action(:insert)
  end
end
