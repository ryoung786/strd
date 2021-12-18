defmodule Strd.LinksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Strd.Links` context.
  """

  @doc """
  Generate a link.
  """
  def link_fixture(attrs \\ %{}) do
    {:ok, link} =
      attrs
      |> Enum.into(%{
        original: "some original",
        short: "some short"
      })
      |> Strd.Links.create_link()

    link
  end
end
