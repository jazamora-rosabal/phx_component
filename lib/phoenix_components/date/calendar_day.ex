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

      selected_day?(assigns) ->
        "border-transparent text-white bg-primary-200 cursor-pointer available-day"

      on_interval?(assigns) ->
        "border-transparent text-white bg-primary-300 cursor-pointer available-day"

      today?(assigns) ->
        "border-dashed border-gray-600 hover:bg-gray-200 cursor-pointer available-day"

      true ->
        "border-transparent text-black bg-white hover:bg-gray-200 cursor-pointer available-day"
    end
  end

  defp other_month?(assigns) do
    Map.take(assigns.day, [:year, :month]) != Map.take(assigns.current_month, [:year, :month])
  end

  defp after_max_date?(%{max_date: max_date}) when max_date == nil, do: false

  defp after_max_date?(%{day: day, max_date: max_date}),
    do: day |> Timex.after?(max_date)

  defp after_max_date?(_), do: false

  defp selected_day?(%{mode: :range, day: day, start_date: start_date, end_date: end_date}) do
    (start_date !== nil && Helper.same_date(day, start_date)) ||
      (end_date !== nil && Helper.same_date(day, end_date))
  end

  defp selected_day?(%{day: day, date: date}) when date != nil do
    Helper.same_date(day, date)
  end

  defp selected_day?(_), do: false

  defp on_interval?(%{mode: :range, day: day, interval: interval} = assigns)
       when interval != nil do
    assigns
    |> other_month?()
    |> check_interval?(day, interval)
  end

  defp on_interval?(_),
    do: false

  defp check_interval?(false, day, interval),
    do: day in interval

  defp check_interval?(_, _),
    do: false

  defp today?(assigns) do
    assigns.day |> Helper.today?(assigns.time_zone)
  end

  defp get_date(date) do
    Timex.format!(date, "%FT%T", :strftime)
  end

  defp get_date_to_js(date) do
    Timex.format!(date, "%m/%d/%Y", :strftime)
  end

  def is_block?(assigns) do
    after_max_date?(assigns) || other_month?(assigns)
  end
end
