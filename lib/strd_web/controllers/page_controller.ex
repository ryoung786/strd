defmodule StrdWeb.PageController do
  use StrdWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
