defmodule Phoenix.Components.CalendarMonthYear do
  use Phoenix.LiveComponent
  use Timex

  alias Calendar.Helper

  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:column_class, column_class(assigns))
    }
  end

  defp column_class(assigns) do
    cond do
      after_max_date?(assigns) ->
        "border-transparent text-gray-300 cursor-not-allowed line-through"

      before_min_date?(assigns) ->
        "border-transparent text-gray-300 cursor-not-allowed line-through"

      current_month_or_year?(assigns) ->
        " border-dashed border-gray-600 hover:bg-gray-200 cursor-pointer"

      true ->
        "border-transparent text-black bg-white hover:bg-gray-200 cursor-pointer"
    end
  end

  defp after_max_date?(assigns) do
    after_max_date?(
      assigns.picker_mode,
      assigns.calendar_mode,
      assigns.calendar,
      assigns.date,
      assigns.max_date
    )
  end

  defp after_max_date?(picker_mode, calendar_mode, calendar, date, max_date) do
    if max_date !== nil,
      do: Helper.after_max_date?(picker_mode, calendar_mode, calendar, date, max_date),
      else: false
  end

  defp before_min_date?(assigns) do
    before_min_date?(
      assigns.picker_mode,
      assigns.calendar_mode,
      assigns.calendar,
      assigns.date,
      assigns.min_date
    )
  end

  def before_min_date?(picker_mode, calendar_mode, calendar, date, min_date) do
    if min_date != nil,
      do: Helper.before_min_date?(picker_mode, calendar_mode, calendar, date, min_date),
      else: false
  end

  defp current_month_or_year?(assigns) do
    Map.take(assigns.date, [:year, :month]) == Map.take(assigns.current_date, [:year, :month])
  end

  defp get_value(date, calendar_mode) do
    if calendar_mode === :month,
      do: date |> Timex.format!("%b", :strftime) |> Timex.month_to_num() |> Helper.short_month(),
      else: Timex.format!(date, "%Y", :strftime)
  end

  # defp get_date(date) do
  #   Timex.format!(date, "%d/%m/%Y", :strftime)
  # end

  defp is_block?(date, min_date, max_date, picker_mode, calendar_mode, calendar) do
    picker_mode |> before_min_date?(calendar_mode, calendar, date, min_date) ||
      picker_mode |> after_max_date?(calendar_mode, calendar, date, max_date)
  end
end
