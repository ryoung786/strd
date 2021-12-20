defmodule StrdWeb.Router do
  use StrdWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {StrdWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", StrdWeb do
    pipe_through :browser

    get "/", LinkController, :index
    post "/", LinkController, :create
    get "/links/:short_url", LinkController, :show

    if Mix.env() in [:dev, :test] do
      import Phoenix.LiveDashboard.Router
      live_dashboard "/dashboard", metrics: StrdWeb.Telemetry
    end

    get "/:short_url", LinkController, :redirect_short_url
  end

  # Other scopes may use custom stacks.
  # scope "/api", StrdWeb do
  #   pipe_through :api
  # end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
