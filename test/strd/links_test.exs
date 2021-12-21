defmodule Strd.LinksTest do
  use Strd.DataCase
  alias Strd.Links

  describe "links" do
    alias Strd.Links.Link
    import Strd.LinksFixtures
    import Strd.AccountsFixtures

    test "get_link!/1 returns the link with given id" do
      link = link_fixture()
      assert Links.get_link!(link.id) == link
    end

    test "increase_view_count increments view count and returns the new count" do
      link = link_fixture()
      assert {1, [1]} = Links.increase_view_count(link.short)
      assert {1, [2]} = Links.increase_view_count(link.short)
      assert {1, [7]} = Links.increase_view_count(link.short, 5)

      assert %Link{view_count: 7} = Links.get_link!(link.id)
    end

    test "get_by_user/1 returns the link with given id" do
      user = user_fixture()

      Links.create_link("https://google.com", user)
      Links.create_link("https://yahoo.com", user)
      assert Links.get_by_user(user) |> Enum.count() == 2
    end

    test "create_link/2 with valid data creates a link" do
      original = "http://foo.com"
      assert {:ok, %Link{} = link} = Links.create_link(original, nil)
      assert link.original == original
      assert String.length(link.short) == 6
    end

    test "create_link/2 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Links.create_link("foo", nil)
      assert {:error, %Ecto.Changeset{}} = Links.create_link("foo.com", nil)
      assert {:error, %Ecto.Changeset{}} = Links.create_link("http://foo", nil)
    end

    test "create_link/3 with valid data creates a link" do
      user = user_fixture()
      {original, short} = {"http://foo.com", "short"}
      assert {:ok, %Link{} = link} = Links.create_link(original, short, user)
      assert link.original == original
      assert link.short == short
      assert link.user_id == user.id
    end

    test "create_link/3 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Links.create_link("foo", "short", nil)
      assert {:error, %Ecto.Changeset{}} = Links.create_link("foo.com", "short", nil)
      assert {:error, %Ecto.Changeset{}} = Links.create_link("http://foo", "short", nil)

      # can't have > character
      assert {:error, %Ecto.Changeset{}} = Links.create_link("http://foo.com", ">short", nil)
      # must be at least 3 characters long
      assert {:error, %Ecto.Changeset{}} = Links.create_link("http://foo.com", "", nil)
    end
  end
end
