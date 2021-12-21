defmodule Strd.Telemetry.ViewCountReporter do
  @moduledoc """
  This is a custom reporter that listens for `links.short.views` counter
  measurement events.  When triggered, it will increase the `view_count`
  of the associated Link by the given amount, and write to the info log.
  """
  use GenServer
  require Logger
  alias Strd.Links

  @metric_event_name [:links, :short]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil)
  end

  @impl true
  def init(_initial_state) do
    Process.flag(:trap_exit, true)

    :ok =
      :telemetry.attach(
        "strd-telemetry-view-count-metric",
        @metric_event_name,
        &handle_event/4,
        nil
      )

    {:ok, nil}
  end

  @impl true
  def terminate(_, _state) do
    :telemetry.detach({__MODULE__, @metric_event_name, self()})
  end

  defp handle_event(_event_name, %{views: views}, %{short_url: short_url}, _config) do
    {_, [total_view]} = Links.increase_view_count(short_url, views)

    Logger.info(
      "Short link #{short_url} got #{views} more view(s). Now has #{total_view} total views"
    )
  end
end
