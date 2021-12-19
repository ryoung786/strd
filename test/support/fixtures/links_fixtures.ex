defmodule Strd.LinksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Strd.Links` context.
  """

  @doc """
  Generate a link.
  """
  def link_fixture(attrs \\ %{}) do
    args =
      attrs
      |> Enum.into(%{
        original: "http://foo.com",
        short: "short"
      })

    {:ok, link} = Strd.Links.create_link(args.original, args.short)

    link
  end
end
