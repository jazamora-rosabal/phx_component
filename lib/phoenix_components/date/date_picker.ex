defmodule Phoenix.Components.DatePicker do
  @moduledoc """
  Documentation for DatePicker.
  """
  use Phoenix.LiveComponent

  use Timex
  require Logger

  alias Calendar.Helper
  alias Timex.Timezone

  @week_start_at :mon

  @tz_default Timezone.name_of(0)

  @default_data %{
    value: nil,
    range_selected: nil,
    show_calendar: false,
    right_month: Timex.now(),
    start_date: nil,
    end_date: nil,
    interval: nil,
    calendar_left_mode: :date,
    calendar_right_mode: :date,
    current_month: Timex.now(),
    current_date: nil,
    calendar_mode: :date
  }

  def mount(socket) do
    {:ok,
     socket
     |> assign(@default_data)
     |> assign(:field_name, "date_field")
     |> assign(label: nil)
     |> assign(placeholder: "Seleccione")
     |> assign(min_date: nil)
     |> assign(max_date: nil)
     |> assign(opens: :left)
     |> assign(picker_mode: :single)
     |> assign(day_names: day_names(@week_start_at))
     |> assign(left_month: Timex.now() |> Timex.shift(months: -1))}
  end

  def update(assigns, socket) do
    # tz_offset = get_tz_offset(assigns)
    socket =
      if assigns.value === nil && socket.assigns.range_selected != nil,
        do: socket |> assign(range_selected: nil) |> assign(show_calendar: false),
        else: socket

    time_zone = get_time_zone(assigns)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:time_zone, time_zone)
     |> assign(:min_date, Helper.one_hundred_years_ago(time_zone))
     |> assign(:max_date, Helper.one_hundred_years_after(time_zone))
     |> assign(:ranges, range_definition(time_zone))
     |> update_picker_mode_single()
     |> update_picker_mode_range()}
  end

  def handle_event("clear", _, socket) do
    send_values(socket.assigns.field_name)

    {:noreply,
     socket
     |> assign(@default_data)
     |> assign(left_month: Timex.now() |> Timex.shift(months: -1))
     |> update_picker_mode_single()
     |> update_picker_mode_range()}
  end

  def handle_event("toogle_calendar_mode", %{"calendar" => "left"}, socket) do
    socket |> toogle_calendar_mode(socket.assigns.calendar_left_mode, :calendar_left_mode)
  end

  def handle_event("toogle_calendar_mode", %{"calendar" => "right"}, socket) do
    socket |> toogle_calendar_mode(socket.assigns.calendar_right_mode, :calendar_right_mode)
  end

  def handle_event("toogle_calendar_mode", _, socket) do
    socket |> toogle_calendar_mode(socket.assigns.calendar_mode, :calendar_mode)
  end

  def handle_event("prev", %{"calendar" => "left"}, socket) do
    calendar_mode = socket.assigns.calendar_left_mode
    left_month = socket.assigns.left_month
    min_date = socket.assigns.min_date
    socket |> previous(calendar_mode, left_month, min_date, :left_month, :week_rows_left)
  end

  def handle_event("prev", %{"calendar" => "right"}, socket) do
    calendar_mode = socket.assigns.calendar_right_mode
    right_month = socket.assigns.right_month
    min_date = socket.assigns.left_month |> Timex.shift(months: 1)
    socket |> previous(calendar_mode, right_month, min_date, :right_month, :week_rows_right)
  end

  def handle_event("prev", _, socket) do
    calendar_mode = socket.assigns.calendar_mode
    current_month = socket.assigns.current_month
    min_date = socket.assigns.min_date
    socket |> previous(calendar_mode, current_month, min_date, :current_month, :week_rows)
  end

  def handle_event("next", %{"calendar" => "left"}, socket) do
    calendar_mode = socket.assigns.calendar_left_mode
    left_month = socket.assigns.left_month
    max_date = socket.assigns.right_month |> Timex.shift(months: -1)
    socket |> next(calendar_mode, left_month, max_date, :left_month, :week_rows_left)
  end

  def handle_event("next", %{"calendar" => "right"}, socket) do
    calendar_mode = socket.assigns.calendar_right_mode
    right_month = socket.assigns.right_month
    max_date = socket.assigns.max_date
    socket |> next(calendar_mode, right_month, max_date, :right_month, :week_rows_right)
  end

  def handle_event("next", _, socket) do
    calendar_mode = socket.assigns.calendar_mode
    current_month = socket.assigns.current_month
    max_date = socket.assigns.max_date
    socket |> next(calendar_mode, current_month, max_date, :current_month, :week_rows)
  end

  def handle_event("pick-date", %{"block" => "true"}, socket) do
    {:noreply, socket}
  end

  def handle_event("pick-date", %{"date" => date, "mode" => "single"}, socket) do
    date = Timex.parse!(date, "%FT%T", :strftime)
    send_values(socket.assigns.field_name, date, date |> Timex.format!("{0D}/{0M}/{YYYY}"))
    {:noreply, socket |> assign(:current_date, date)}
  end

  def handle_event("pick-date", %{"date" => date}, socket) do
    date = Timex.parse!(date, "%FT%T", :strftime)
    start_date = socket.assigns.start_date
    end_date = socket.assigns.end_date
    {:noreply, socket |> assign(:interval, nil) |> pick_date(start_date, end_date, date)}
  end

  def handle_event("change_month_or_year", %{"block" => "true"}, socket) do
    {:noreply, socket}
  end

  def handle_event("change_month_or_year", %{"date" => date, "calendar" => "left"}, socket) do
    case Timex.parse(date, "{ISO:Extended:Z}") do
      {:ok, date} ->
        calendar_mode = socket.assigns.calendar_left_mode

        {:noreply,
         socket
         |> change_month_or_year(
           calendar_mode,
           date,
           :left_month,
           :week_rows_left,
           :calendar_left_mode
         )}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("change_month_or_year", %{"date" => date, "calendar" => "right"}, socket) do
    case Timex.parse(date, "{ISO:Extended:Z}") do
      {:ok, date} ->
        calendar_mode = socket.assigns.calendar_right_mode

        {:noreply,
         socket
         |> change_month_or_year(
           calendar_mode,
           date,
           :right_month,
           :week_rows_right,
           :calendar_right_mode
         )}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("change_month_or_year", %{"date" => date}, socket) do
    case Timex.parse(date, "{ISO:Extended:Z}") do
      {:ok, date} ->
        calendar_mode = socket.assigns.calendar_mode

        {:noreply,
         socket
         |> change_month_or_year(calendar_mode, date, :current_month, :week_rows, :calendar_mode)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("select_option", %{"key" => keySelected}, socket) do
    socket = socket |> assign(:range_selected, String.to_atom(keySelected))
    {:noreply, socket |> get_range_by_option_selected(keySelected)}
  end

  # CLEAR VALUE
  defp send_values(target) do
    Logger.info("Limpiando valores del DatePicker")

    send(
      self(),
      {__MODULE__, :picker_value_changed, target, nil}
    )
  end

  # SET VALUE FOR SINGLE PICKER
  defp send_values(target, date, values) do
    date_utc = date |> Timezone.convert(@tz_default) |> Timex.format!("%FT%T", :strftime)
    Logger.info("Fecha seleccionada en LocalTime: [#{values}]")
    Logger.info("Fecha seleccionada en UTC: #{date_utc}")

    send(
      self(),
      {__MODULE__, :picker_value_changed, target, %{date_utc: date_utc, local_time: values}}
    )
  end

  # SET VALUE FOR RANGE PICKER
  defp send_values(target, start_date, end_date, values) do
    start_date_utc =
      start_date |> Timezone.convert(@tz_default) |> Timex.format!("%FT%T", :strftime)

    end_date_utc = end_date |> Timezone.convert(@tz_default) |> Timex.format!("%FT%T", :strftime)
    Logger.info("Rango seleccionado en LocalTime: [#{values}]")
    Logger.info("Rango seleccionado en UTC: [#{start_date_utc} - #{end_date_utc}]")

    send(
      self(),
      {__MODULE__, :picker_value_changed, target,
       %{min_date: start_date_utc, max_date: end_date_utc, range: values}}
    )
  end

  # PICK DATE
  defp pick_date(socket, start_date, end_date, date)
       when is_nil(start_date) === false and is_nil(end_date) === false do
    socket |> assign(:start_date, date) |> assign(:end_date, nil)
  end

  defp pick_date(socket, start_date, _end_date, date) when is_nil(start_date) do
    socket |> assign(:start_date, date)
  end

  defp pick_date(socket, start_date, _end_date, date) do
    end_date = date |> Timex.end_of_day()

    if start_date |> Timex.before?(end_date) do
      tz_offset = socket.assigns.tz_offset
      new_interval = Timex.Interval.new(from: start_date, until: end_date, right_open: false)

      values =
        Timex.format!(start_date, "{0D}/{0M}/{YYYY}") <>
          " - " <> Timex.format!(end_date, "{0D}/{0M}/{YYYY}")

      end_date_to_utc = end_date |> Timex.shift(hours: -tz_offset)
      send_values(socket.assigns.field_name, start_date, end_date_to_utc, values)

      socket
      |> assign(:end_date, end_date)
      |> assign(:interval, new_interval)
    else
      socket |> assign(:start_date, date)
    end
  end

  # PREVIOUS DATE
  defp previous(socket, calendar_mode, date, min_date, target_date, target_week) do
    temporal_month = get_prev_date(calendar_mode, date, min_date)

    {:noreply,
     socket
     |> assign(target_date, temporal_month)
     |> assign(target_week, week_rows(temporal_month))}
  end

  defp get_prev_date(:month, current_month, min_date) do
    if min_date != nil do
      diff = Timex.diff(current_month, min_date, :months)

      if diff > 12,
        do: Timex.shift(current_month, years: -1),
        else: min_date
    else
      Timex.shift(current_month, years: -1)
    end
  end

  defp get_prev_date(:year, current_month, min_date) do
    if min_date != nil do
      diff = Timex.diff(current_month, min_date, :months)

      if diff > 120,
        do: Timex.shift(current_month, years: -10),
        else: min_date
    else
      Timex.shift(current_month, years: -10)
    end
  end

  defp get_prev_date(_calendar_mode, current_month, min_date) do
    if min_date != nil do
      diff = Timex.diff(current_month, min_date, :months)

      if diff > 1,
        do: Timex.shift(current_month, months: -1),
        else: min_date
    else
      Timex.shift(current_month, months: -1)
    end
  end

  # NEXT DATES
  defp next(socket, calendar_mode, date, max_date, target_date, target_week) do
    temporal_month = get_next_date(calendar_mode, date, max_date)

    {:noreply,
     socket
     |> assign(target_date, temporal_month)
     |> assign(target_week, week_rows(temporal_month))}
  end

  defp get_next_date(:month, current_month, max_date) do
    if max_date != nil do
      diff = Timex.diff(max_date, current_month, :months)

      if diff > 12,
        do: Timex.shift(current_month, years: 1),
        else: max_date
    else
      Timex.shift(current_month, years: 1)
    end
  end

  defp get_next_date(:year, current_month, max_date) do
    if max_date != nil do
      diff = Timex.diff(max_date, current_month, :months)

      if diff > 120,
        do: Timex.shift(current_month, years: 10),
        else: max_date
    else
      Timex.shift(current_month, years: 10)
    end
  end

  defp get_next_date(_calendar_mode, current_month, max_date) do
    if max_date != nil do
      diff = Timex.diff(max_date, current_month, :months)

      if diff > 1,
        do: Timex.shift(current_month, months: 1),
        else: max_date
    else
      Timex.shift(current_month, months: 1)
    end
  end

  # CHANGE MONTH OR YEAR
  defp change_month_or_year(socket, :month, date, target_date, target_week, target_calendar_mode) do
    socket
    |> assign(target_date, date)
    |> assign(target_week, week_rows(date))
    |> assign(target_calendar_mode, :date)
  end

  defp change_month_or_year(socket, :year, date, target_date, target_week, target_calendar_mode) do
    socket
    |> assign(target_date, date)
    |> assign(target_week, week_rows(date))
    |> assign(target_calendar_mode, :month)
  end

  # GET DEFINED RANGE OR CUSTOM
  defp get_range_by_option_selected(socket, "custom") do
    socket |> assign(:show_calendar, true) |> reset_picker_mode_range()
  end

  defp get_range_by_option_selected(socket, keySelected) do
    socket |> assign(:show_calendar, false) |> get_range_value_of_definition(keySelected)
  end

  # ----> HELPER FUNCTIONS <----

  defp generate_id_calendar(parent_id, calendar, date) do
    date_format = date |> Timex.format!("%m/%d/%Y", :strftime)

    case calendar do
      "left" -> "#{parent_id}_left_month-#{date_format}"
      _ -> "#{parent_id}_right_month-#{date_format}"
    end
  end

  defp toogle_calendar_mode(socket, calendar_mode, target) do
    # { :noreply, socket |> assign(target, :month) }
    case calendar_mode do
      :date ->
        {:noreply, socket |> assign(target, :month)}

      :month ->
        {:noreply, socket |> assign(target, :year)}

      _ ->
        {:noreply, socket}
    end
  end

  defp get_month_or_years(calendar_mode, current_date) do
    case calendar_mode do
      :month -> current_date |> get_month_definition()
      _ -> current_date |> get_years_definition()
    end
  end

  defp get_years_definition(date) do
    current_year = date |> Map.take([:year]) |> Map.get(:year)

    create_10_years_range(date, 1, 10)
    |> Enum.map(&Timex.shift(date, years: &1 - current_year))
    |> Enum.chunk_every(3)
  end

  defp get_month_definition(date) do
    current_month = date |> Map.take([:month]) |> Map.get(:month)
    1..12 |> Enum.map(&Timex.shift(date, months: &1 - current_month)) |> Enum.chunk_every(3)
  end

  def range_definition(time_zone) do
    [
      today: %{dates: Helper.now(time_zone) |> range_in_days(), name: "Hoy"},
      yesterday: %{
        dates: Helper.now(time_zone) |> Timex.shift(days: -1) |> range_in_days(),
        name: "Ayer"
      },
      last_7days: %{
        dates:
          Helper.now(time_zone) |> Timex.shift(days: -6) |> range_in_days(Helper.now(time_zone)),
        name: "Últimos 7 días"
      },
      last_30days: %{
        dates:
          Helper.now(time_zone) |> Timex.shift(days: -29) |> range_in_days(Helper.now(time_zone)),
        name: "Últimos 30 días"
      },
      this_month: %{dates: Helper.now(time_zone) |> range_this_month(), name: "Mes actual"},
      last_month: %{
        dates: Helper.now(time_zone) |> Timex.shift(months: -1) |> range_in_month(),
        name: "Mes pasado"
      },
      custom: %{dates: [], name: "Personalizado"}
    ]
  end

  defp range_in_days(start_date, end_date) do
    [start_date |> Timex.beginning_of_day(), end_date |> Timex.end_of_day()]
  end

  defp range_in_days(date) do
    [date |> Timex.beginning_of_day(), date |> Timex.end_of_day()]
  end

  defp range_this_month(date) do
    [date |> Timex.beginning_of_month(), date |> Timex.end_of_day()]
  end

  defp range_in_month(date) do
    [date |> Timex.beginning_of_month(), date |> Timex.end_of_month()]
  end

  defp get_header_title(date, calendar_mode) do
    case calendar_mode do
      :month ->
        Timex.format!(date, "%Y", :strftime)

      :year ->
        range_years = create_10_years_range(date, 0, 9) |> Enum.to_list()
        "#{List.first(range_years)} - #{List.last(range_years)}"

      _ ->
        month = Timex.format!(date, "%B", :strftime) |> Timex.month_to_num() |> Helper.sp_month()
        year = Timex.format!(date, "%Y", :strftime)
        "#{month} #{year}"
    end
  end

  defp create_10_years_range(date, minus_offset, plus_offset) do
    current_year = date |> Map.take([:year]) |> Map.get(:year)
    temporal_rem = current_year |> rem(10)
    (current_year - temporal_rem - minus_offset)..(current_year + plus_offset - temporal_rem)
  end

  defp day_names(:mon), do: [1, 2, 3, 4, 5, 6, 7] |> Enum.map(&Helper.days_of_week/1)
  defp day_names(_), do: [7, 1, 2, 3, 4, 5, 6] |> Enum.map(&Helper.days_of_week/1)

  defp week_rows(month) do
    first =
      month
      |> Timex.beginning_of_month()
      |> Timex.beginning_of_week(@week_start_at)

    last =
      month
      |> Timex.end_of_month()
      |> Timex.end_of_week(@week_start_at)

    diff = Timex.diff(last, first, :weeks)

    {new_first, new_last} =
      case diff do
        3 ->
          {first |> Timex.shift(weeks: -1), last |> Timex.shift(weeks: 1)}

        4 ->
          diff_first = Timex.diff(month |> Timex.beginning_of_month(), first)
          diff_last = Timex.diff(last, month |> Timex.end_of_month())

          if diff_first <= diff_last do
            first = first |> Timex.shift(weeks: -1)
            {first, last}
          else
            last = last |> Timex.shift(weeks: 1)
            {first, last}
          end

        _ ->
          {first, last}
      end

    Interval.new(from: new_first, until: new_last)
    |> Enum.map(& &1)
    |> Enum.chunk_every(7)
  end

  # defp get_short_month(date) do
  #   Timex.format!(date, "%B", :strftime) |> Timex.month_to_num() |> Helper.short_month()
  # end

  defp is_custom_range?(key) do
    key === String.to_atom("custom")
  end

  defp get_range_value_of_definition(socket, key) do
    {_, values} = socket.assigns.ranges |> Enum.find(fn {k, _} -> k === String.to_atom(key) end)

    dates =
      values.dates |> Enum.map(&(&1 |> Timex.format!("{0D}/{0M}/{YYYY}"))) |> Enum.join(" - ")

    start_date = values.dates |> List.first()
    end_date = values.dates |> List.last()
    send_values(socket.assigns.field_name, start_date, end_date, dates)
    socket
  end

  defp get_time_zone(assigns) do
    if Map.has_key?(assigns, :tz_offset),
      do: assigns.tz_offset |> Helper.get_time_zone() |> ok_time_zone(),
      else: @tz_default
  end

  defp ok_time_zone(time_zone) do
    if Timex.is_valid_timezone?(time_zone), do: time_zone, else: @tz_default
  end

  def update_picker_mode_single(socket) do
    current_month = socket.assigns.current_month |> Timezone.convert(socket.assigns.time_zone)

    socket
    |> assign(:current_month, current_month)
    |> assign(:week_rows, week_rows(current_month))
  end

  def update_picker_mode_range(socket) do
    time_zone = socket.assigns.time_zone

    right_month =
      socket.assigns.right_month |> Timezone.convert(time_zone) |> Timex.beginning_of_month()

    left_month =
      socket.assigns.left_month |> Timezone.convert(time_zone) |> Timex.beginning_of_month()

    socket |> set_values_to_picker_mode_range(left_month, right_month)
  end

  def reset_picker_mode_range(socket) do
    time_zone = socket.assigns.time_zone
    right_month = Helper.now(time_zone) |> Timex.beginning_of_month()
    left_month = Timex.shift(right_month, months: -1) |> Timex.beginning_of_month()

    socket
    |> set_values_to_picker_mode_range(left_month, right_month)
    |> assign(:start_date, nil)
    |> assign(:end_date, nil)
    |> assign(:interval, nil)
  end

  defp set_values_to_picker_mode_range(socket, left_month, right_month) do
    socket
    |> assign(:left_month, left_month)
    |> assign(:right_month, right_month)
    |> assign(:week_rows_left, week_rows(left_month))
    |> assign(:week_rows_right, week_rows(right_month))
  end
end

defmodule Calendar.Helper do
  alias Timex.Timezone

  def before_than_100_years?(date, time_zone) do
    one_hundred_ago = Timex.shift(time_zone |> now(), months: -1200)
    if Timex.before?(date, one_hundred_ago), do: true, else: false
  end

  def after_than_100_years?(date, time_zone) do
    one_hundred_after = Timex.shift(time_zone |> now(), months: 1200)
    if Timex.after?(date, one_hundred_after), do: true, else: false
  end

  def one_hundred_years_ago(time_zone) do
    Timex.shift(time_zone |> now(), months: -1200) |> Timex.beginning_of_year()
  end

  def one_hundred_years_after(time_zone) do
    Timex.shift(time_zone |> now(), months: 1200)
    |> Timex.end_of_year()
    |> Timex.beginning_of_month()
  end

  def today?(date, time_zone) do
    today = time_zone |> now()
    Map.take(date, [:year, :month, :day]) == Map.take(today, [:year, :month, :day])
  end

  def get_time_zone(offset) do
    Timezone.name_of(offset)
  end

  def now(timezone_name) do
    Timezone.convert(Timex.now(), timezone_name)
  end

  def now() do
    Timex.now()
  end

  def before_min_date?(:range, :month, "right", date, min_date) do
    case Timex.compare(date, min_date) do
      1 -> false
      _ -> true
    end
  end

  def before_min_date?(_picker_mode, :month, _calendar, date, min_date) do
    case Timex.compare(date, min_date) do
      -1 -> true
      _ -> false
    end
  end

  def before_min_date?(_picker_mode, :year, "right", date, min_date) do
    date = Map.take(date, [:year, :month])
    min_date = Map.take(min_date, [:year, :month])
    date_year = date |> Map.get(:year)
    min_date_year = min_date |> Map.get(:year)

    if date_year < min_date_year,
      do: true,
      else:
        before_min_date_with_same_years(date_year === min_date_year, min_date |> Map.get(:month))
  end

  def before_min_date?(_picker_mode, :year, _calendar, date, min_date) do
    date_year = Map.take(date, [:year]) |> Map.get(:year)
    min_date_year = Map.take(min_date, [:year]) |> Map.get(:year)
    if date_year < min_date_year, do: true, else: false
  end

  def before_min_date?(_picker_mode, _mode, _calendar, date, min_date) do
    date |> Timex.before?(min_date)
  end

  def after_max_date?(:range, :month, "left", date, max_date) do
    case Timex.compare(date, max_date) do
      -1 -> false
      _ -> true
    end
  end

  def after_max_date?(_picker_mode, :month, _calendar, date, max_date) do
    case Timex.compare(date, max_date) do
      1 -> true
      _ -> false
    end
  end

  def after_max_date?(_picker_mode, :year, _calendar, date, max_date) do
    date = Map.take(date, [:year, :month])
    max_date = Map.take(max_date, [:year, :month])
    date_year = date |> Map.get(:year)
    max_date_year = max_date |> Map.get(:year)

    if date_year > max_date_year,
      do: true,
      else:
        after_max_date_with_same_years(date_year === max_date_year, max_date |> Map.get(:month))
  end

  def after_max_date?(_picker_mode, _mode, _calendar, date, max_date) do
    date |> Timex.after?(max_date)
  end

  def same_date?(date0, date1) do
    Map.take(date0, [:year, :month, :day]) == Map.take(date1, [:year, :month, :day])
  end

  defp before_min_date_with_same_years(same_year, min_date_month) do
    case same_year do
      true -> if min_date_month === 12, do: true, else: false
      _ -> false
    end
  end

  defp after_max_date_with_same_years(same_year, max_date_month) do
    case same_year do
      true -> if max_date_month === 1, do: true, else: false
      _ -> false
    end
  end

  def days_of_week(2), do: "Mar"
  def days_of_week(1), do: "Lun"
  def days_of_week(3), do: "Mie"
  def days_of_week(4), do: "Jue"
  def days_of_week(5), do: "Vie"
  def days_of_week(6), do: "Sab"
  def days_of_week(7), do: "Dom"

  def sp_month(1), do: "Enero"
  def sp_month(2), do: "Febrero"
  def sp_month(3), do: "Marzo "
  def sp_month(4), do: "Abril"
  def sp_month(5), do: "Mayo"
  def sp_month(6), do: "Junio"
  def sp_month(7), do: "Julio"
  def sp_month(8), do: "Agosto"
  def sp_month(9), do: "Septiembre"
  def sp_month(10), do: "Octubre"
  def sp_month(11), do: "Noviembre"
  def sp_month(12), do: "Diciembre"

  def short_month(1), do: "Ene"
  def short_month(2), do: "Feb"
  def short_month(3), do: "Mar "
  def short_month(4), do: "Abr"
  def short_month(5), do: "May"
  def short_month(6), do: "Jun"
  def short_month(7), do: "Jul"
  def short_month(8), do: "Ago"
  def short_month(9), do: "Sep"
  def short_month(10), do: "Oct"
  def short_month(11), do: "Nov"
  def short_month(12), do: "Dic"
end
