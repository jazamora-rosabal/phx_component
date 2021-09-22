defmodule Phoenix.Components.CalendarDay do
  use Phoenix.LiveComponent
  use Timex
  alias Phoenix.Components.DatePicker.Helpers.{Range, Calendar}

  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
      |> assign(:day_class, day_class(assigns))
    }
  end


  defp day_class(%{selection_class: class, selection_hover_class: hover_class} = assigns) do
    cond do
      other_month?(assigns) ->
        "border-transparent text-gray-300 cursor-not-allowed"

      after_max_date?(assigns) ->
        "border-transparent text-gray-300 cursor-not-allowed line-through"

      selected_day?(assigns) ->
        "border-transparent text-white bg-#{class} cursor-pointer available-day"

      on_interval?(assigns) ->
        "border-transparent text-white bg-#{hover_class} cursor-pointer available-day"

      today?(assigns) ->
        "border-dashed border-gray-600 hover:bg-gray-200 cursor-pointer available-day"

      true ->
        "border-transparent text-black bg-white hover:bg-gray-200 cursor-pointer available-day"
    end
  end

  defp other_month?(%{day: day, current_month: current_month}) do
    Map.take(day, [:year, :month]) != Map.take(current_month, [:year, :month])
  end

  defp other_month?(_assigns), do: false

  defp after_max_date?(%{max_date: max_date}) when max_date == nil, do: false

  defp after_max_date?(%{day: day, max_date: max_date}),
    do: day |> Timex.after?(max_date)

  defp after_max_date?(_), do: false

  defp selected_day?(%{mode: false, day: day, start_date: start_date, end_date: end_date}) do
    (start_date !== nil && Calendar.same_date?(day, start_date)) ||
      (end_date !== nil && Calendar.same_date?(day, end_date))
  end

  defp selected_day?(%{day: day, date: date}) when date != nil do
    Calendar.same_date?(day, date)
  end

  defp selected_day?(_), do: false

  defp on_interval?(%{mode: false, day: day, range: %Range{interval: interval}} = assigns)
       when interval != nil do
    assigns
    |> other_month?()
    |> check_interval?(day, interval)
  end

  defp on_interval?(_), do: false

  defp check_interval?(true, _, _), do: false

  defp check_interval?(false, day, interval), do: day in interval

  defp today?(assigns), do: assigns.day |> Calendar.today?(assigns.time_zone)

  defp get_date(date), do: Timex.format!(date, "%FT%T", :strftime)

  defp get_date_to_js(date), do: Timex.format!(date, "%m/%d/%Y", :strftime)

  def is_block?(assigns), do: after_max_date?(assigns) || other_month?(assigns)
end
