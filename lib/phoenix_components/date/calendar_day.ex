defmodule Phoenix.Components.CalendarDay do
  use Phoenix.LiveComponent
  use Timex

  alias Calendar.Helper

  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:day_class, day_class(assigns))
    }
  end

  defp day_class(assigns) do
    cond do
      other_month?(assigns) ->
        "border-transparent text-gray-300 cursor-not-allowed"

      after_max_date?(assigns) ->
        "border-transparent text-gray-300 cursor-not-allowed line-through"

      start_date_or_end_date_or_current_date?(assigns) ->
        "border-transparent text-white bg-primary-200 cursor-pointer available-day"

      on_interval?(assigns) ->
        "border-transparent text-white bg-primary-300 cursor-pointer available-day"

      today?(assigns) ->
        "border-dashed border-gray-600 hover:bg-gray-200 cursor-pointer available-day"

      true ->
        "border-transparent text-black bg-white hover:bg-gray-200 cursor-pointer available-day"
    end
  end

  defp start_date_or_end_date_or_current_date?(assigns) do
    if assigns.mode === :range do
      (assigns.start_date !== nil &&
         Map.take(assigns.day, [:year, :month, :day]) ==
           Map.take(assigns.start_date, [:year, :month, :day])) ||
        (assigns.end_date !== nil &&
           Map.take(assigns.day, [:year, :month, :day]) ==
             Map.take(assigns.end_date, [:year, :month, :day]))
    else
      assigns.date !== nil &&
        Map.take(assigns.day, [:year, :month, :day]) ==
          Map.take(assigns.date, [:year, :month, :day])
    end
  end

  defp on_interval?(assigns) do
    if assigns.mode === :range && assigns.interval !== nil && other_month?(assigns) === false,
      do: assigns.day in assigns.interval,
      else: false
  end

  defp today?(assigns) do
    assigns.day |> Helper.today?(assigns.time_zone)
  end

  defp other_month?(assigns) do
    other_month?(assigns.day, assigns.current_month)
  end

  defp other_month?(day, current_month) do
    Map.take(day, [:year, :month]) != Map.take(current_month, [:year, :month])
  end

  defp after_max_date?(assigns) do
    after_max_date?(assigns.day, assigns.max_date)
  end

  defp after_max_date?(day, max_date) do
    if max_date !== nil, do: day |> Timex.after?(max_date), else: false
  end

  defp get_date(date) do
    Timex.format!(date, "%FT%T", :strftime)
  end

  defp get_date_to_js(date) do
    Timex.format!(date, "%m/%d/%Y", :strftime)
  end

  def is_block?(day, current_month, max_date) do
    after_max_date?(day, max_date) || other_month?(day, current_month)
  end
end
