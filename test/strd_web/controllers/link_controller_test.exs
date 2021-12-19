defmodule StrdWeb.LinkControllerTest do
  use StrdWeb.ConnCase

  @create_attrs %{original: "http://foo.com"}
  @invalid_attrs %{original: "foo"}

  describe "index" do
    test "has form to create a link", %{conn: conn} do
      conn = get(conn, Routes.link_path(conn, :index))
      assert html_response(conn, 200) =~ "Create a short link"
    end
  end

  describe "create link" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.link_path(conn, :create), link: @create_attrs)

      assert %{short_url: short_url} = redirected_params(conn)
      assert redirected_to(conn) == Routes.link_path(conn, :show, short_url)

      conn = get(conn, Routes.link_path(conn, :show, short_url))
      assert html_response(conn, 200) =~ "<h1>Link</h1>"
    end

    test "renders errors when link has no .com", %{conn: conn} do
      conn = post(conn, Routes.link_path(conn, :create), link: %{original: "http://foo"})
      assert html_response(conn, 200) =~ "Invalid host name"
    end

    test "renders errors when link doesn't start with http or https", %{conn: conn} do
      conn = post(conn, Routes.link_path(conn, :create), link: %{original: "htt://foo.com"})
      assert html_response(conn, 200) =~ "URL must begin with"
    end

    test "renders errors when link doesn't have a host name", %{conn: conn} do
      conn = post(conn, Routes.link_path(conn, :create), link: %{original: "https://.com"})
      assert html_response(conn, 200) =~ "Invalid host name"
    end
  end

  describe "redirect_short_url" do
    test "redirects to the original link", %{conn: conn} do
      conn = post(conn, Routes.link_path(conn, :create), link: @create_attrs)
      %{short_url: short_url} = redirected_params(conn)

      conn = get(conn, Routes.link_path(conn, :redirect_short_url, short_url))
      assert redirected_to(conn) == @create_attrs.original
    end
  end
end
