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

  defp column_class(%{calendar_mode: mode} = assigns) do
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
    |> x_padding(mode)
  end

  defp column_class(_assigns) do
    "border-transparent text-black bg-white hover:bg-gray-200 cursor-pointer"
  end

  defp after_max_date?(%{max_date: max_date} = assigns) when max_date == nil, do: false

  defp after_max_date?(
         %{
           picker_mode: picker_mode,
           calendar_mode: calendar_mode,
           calendar: calendar,
           date: date,
           max_date: max_date
         } = assigns
       ),
       do: Helper.after_max_date?(picker_mode, calendar_mode, calendar, date, max_date)

  defp after_max_date?(_), do: false

  defp before_min_date?(%{min_date: min_date} = assigns) when min_date == nil, do: false

  defp before_min_date?(
         %{
           picker_mode: picker_mode,
           calendar_mode: calendar_mode,
           calendar: calendar,
           date: date,
           min_date: min_date
         } = assigns
       ),
       do: Helper.before_min_date?(picker_mode, calendar_mode, calendar, date, min_date)

  defp before_min_date?(_), do: false

  defp current_month_or_year?(assigns) do
    Map.take(assigns.date, [:year, :month]) == Map.take(assigns.current_date, [:year, :month])
  end

  defp get_value(date, :month),
    do: date |> Timex.format!("%b", :strftime) |> Timex.month_to_num() |> Helper.short_month()

  defp get_value(date, _),
    do: Timex.format!(date, "%Y", :strftime)

  defp is_block?(assigns) do
    before_min_date?(assigns) || after_max_date?(assigns)
  end

  defp x_padding(clazz, :month) do
    "#{clazz} px-8"
  end

  defp x_padding(clazz, _) do
    "#{clazz} px-7"
  end
end
