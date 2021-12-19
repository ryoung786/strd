defmodule StrdWeb.LinkView do
  use StrdWeb, :view

  def full_short_link(short) do
    StrdWeb.Endpoint.url() <> "/#{short}"
  end
end
