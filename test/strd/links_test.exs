defmodule Strd.LinksTest do
  use Strd.DataCase
  alias Strd.Links

  describe "links" do
    alias Strd.Links.Link
    import Strd.LinksFixtures

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

    test "create_link/1 with valid data creates a link" do
      original = "http://foo.com"
      assert {:ok, %Link{} = link} = Links.create_link(original)
      assert link.original == original
      assert String.length(link.short) == 6
    end

    test "create_link/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Links.create_link("foo")
      assert {:error, %Ecto.Changeset{}} = Links.create_link("foo.com")
      assert {:error, %Ecto.Changeset{}} = Links.create_link("http://foo")
    end

    test "create_link/2 with valid data creates a link" do
      {original, short} = {"http://foo.com", "short"}
      assert {:ok, %Link{} = link} = Links.create_link(original, short)
      assert link.original == original
      assert link.short == short
    end

    test "create_link/2 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Links.create_link("foo", "short")
      assert {:error, %Ecto.Changeset{}} = Links.create_link("foo.com", "short")
      assert {:error, %Ecto.Changeset{}} = Links.create_link("http://foo", "short")

      # can't have > character
      assert {:error, %Ecto.Changeset{}} = Links.create_link("http://foo.com", ">short")
      # must be at least 3 characters long
      assert {:error, %Ecto.Changeset{}} = Links.create_link("http://foo.com", "")
    end
  end
end
