defmodule Phoenix.Components.DatePicker.Helpers do
  defmodule Range do
    require Logger
    use Timex
    alias Phoenix.Components.DatePicker.Helpers.Calendar

    @tz_default Timezone.name_of(0)

    @default [
      today: %{label: "Hoy", amount: 0, in: :days},
      yesterday: %{label: "Ayer", amount: -1, in: :days},
      last_7days: %{label: "Últimos 7 días", amount: -7, in: :days},
      last_30days: %{label: "Últimos 30 días", amount: -30, in: :days},
      this_month: %{label: "Mes actual", amount: 0, in: :months},
      last_month: %{label: "Mes pasado", amount: -1, in: :months},
      this_year: %{label: "Año actual", amount: 0, in: :years}
      # last_year: %{label: "Año pasado", amount: -1, in: :years},
    ]

    defstruct [:key, :label, interval: nil, value: nil]

    def new(%{label: l, amount: a, in: step} = elem, now) when is_binary(l) and is_integer(a) and is_atom(step) do
      dates(a, step, now)
      |> case do
        nil ->
          Logger.debug("El rango: #{inspect(elem)}, no cumple con la especificacion definida para el componente.")
          nil
        {from, to} ->
          %__MODULE__{
            key: generate_key(a, step),
            label: l,
            interval: new_interval(from, to),
            value: new_value(from, to)
            }
      end
    end

    def new(%{label: l, amount: a, in: step} = elem, now) when is_binary(l) and is_binary(a) and is_binary(step),
      do: new(%{elem | amount: String.to_integer(a), in: String.to_existing_atom(step)}, now)

    def new(default_key, now) when is_atom(default_key) do
      @default
      |> Enum.find(fn {k,_} -> k == default_key end)
      |> case do
        nil ->
          Logger.debug("El rango para la llave: #{inspect(default_key)}, no esta definido.")
          nil
        {_, elem} ->
          new(elem, now)
      end
    end

    def new(default_key, now) when is_binary(default_key), do: new(String.to_atom(default_key), now)

    def new(elem, _now) do
      Logger.debug("El rango: #{inspect(elem)}, no cumple con la especificacion definida para el componente.")
      nil
    end

    def custom(label),
      do: %__MODULE__{ key: "custom", label: label}

    def defaults(now) do
      @default
      |> Enum.map(fn {_, elem} -> new(elem, now) end)
    end

    def generate_key(0, :days), do: "today"
    def generate_key(1, :days), do: "tomorrow"
    def generate_key(-1, :days), do: "yesterday"
    def generate_key(n, step) when n == 0, do: "this_#{Atom.to_string(step)}"
    def generate_key(n, step) when n > 1, do: "next_#{n}#{Atom.to_string(step)}"
    def generate_key(n, step), do: "last_#{abs(n)}#{Atom.to_string(step)}"

    # Hoy
    defp dates(0, :days, now),
     do: now |> Calendar.range_in_days()

    # Mañana
    defp dates(1, :days, now),
     do: now |> Timex.shift(days: 1) |> Calendar.range_in_days()

    # Ayer
    defp dates(-1, :days, now),
     do: now |> Timex.shift(days: -1) |> Calendar.range_in_days()

    # Proximos n dias
    defp dates(n, :days, now) when n > 1,
     do: now |> Timex.shift(days: 1) |> Calendar.range_in_days(now |> Timex.shift(days: n))

    # Ultimos n dias
    defp dates(n, :days, now),
     do: now |> Timex.shift(days: (n + 1)) |> Calendar.range_in_days(now)

    # Este mes
    defp dates(0, :months, now),
      do: now |> Calendar.range_in_months()

    # Proximo mes
    defp dates(1, :months, now),
      do: now |> Timex.shift(months: 1) |> Calendar.range_in_months()

    # Pasado mes
    defp dates(-1, :months, now),
      do: now |> Timex.shift(months: -1) |> Calendar.range_in_months()

    # Proximos n meses
    defp dates(n, :months, now) when n > 1,
      do: now |> Timex.shift(months: 1) |> Calendar.range_in_months(now |> Timex.shift(months: n))

    # Ultimos n meses
    defp dates(n, :months, now),
      do: now |> Timex.shift(months: (n + 1)) |> Calendar.range_in_months(now)

    # Este año
    defp dates(0, :years, now),
      do: now |> Calendar.range_in_years()
    # Proximo año
    defp dates(1, :years, now),
      do: now |> Timex.shift(years: 1) |> Calendar.range_in_years()
    # Año pasado
    defp dates(-1, :years, now),
      do: now |> Timex.shift(years: -1) |> Calendar.range_in_years()
    # Proximos n años
    defp dates(n, :years, now) when n > 1,
      do: now |> Timex.shift(years: 1) |> Calendar.range_in_years(now |> Timex.shift(years: n))
    # Ultimos n años
    defp dates(n, :years, now),
      do: now |> Timex.shift(years: (n + 1)) |> Calendar.range_in_years(now)

    defp dates(_n, _step, _now),
      do: nil
    #
    defp new_interval(start_date, end_date) do
      Interval.new(
        from: start_date |> Timezone.convert(@tz_default),
        until: end_date |> Timezone.convert(@tz_default),
        right_open: false
        )
    end

    defp new_value(start_date, end_date),
      do: Timex.format!(start_date, "{0D}/{0M}/{YYYY}") <> " - " <> Timex.format!(end_date, "{0D}/{0M}/{YYYY}")

  end

  defmodule Calendar do
    alias Timex.Timezone

    def before_than_100_years?(date, time_zone),
      do: Timex.before?(date, one_hundred_years_ago(time_zone))

    def after_than_100_years?(date, time_zone), do:
      Timex.after?(date, one_hundred_years_after(time_zone))

    def one_hundred_years_ago(time_zone) do
      time_zone
      |> now()
      |> Timex.shift(months: -1200)
      |> Timex.beginning_of_year()
    end

    def one_hundred_years_after(time_zone) do
      time_zone
      |> now()
      |> Timex.shift(months: 1200)
      |> Timex.end_of_year()
      |> Timex.end_of_month()
    end

    def today?(date, time_zone) do
      time_zone
      |> now()
      |> same_date?(date)
    end

    def get_time_zone(offset) do
      Timezone.name_of(offset)
    end

    def now(timezone_name) do
      now() |> Timezone.convert(timezone_name)
    end

    def now() do
      Timex.now()
    end

    def before_min_date?(false, :month, "right", date, min_date) do
      case Timex.compare(date, min_date |> Timex.end_of_month()) do
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

    def after_max_date?(false, :month, "left", date, max_date) do
      case Timex.compare(date, max_date |> Timex.beginning_of_month()) do
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

    def same_date?(date0, date1),
      do: Map.take(date0, [:year, :month, :day]) == Map.take(date1, [:year, :month, :day])

    def range_in_days(start_date, end_date),
    do: { start_date |> Timex.beginning_of_day(), end_date |> Timex.end_of_day() }

    def range_in_days(date),
      do: { date |> Timex.beginning_of_day(), date |> Timex.end_of_day() }

    def range_in_months(start_date, end_date),
      do: { start_date |> Timex.beginning_of_month(), end_date |> Timex.end_of_month() }

    def range_in_months(date),
      do: { date |> Timex.beginning_of_month(), date |> Timex.end_of_month() }

    def range_in_years(start_date, end_date),
      do: { start_date |> Timex.beginning_of_year(), end_date |> Timex.end_of_year() }

    def range_in_years(date),
      do: { date |> Timex.beginning_of_year(), date |> Timex.end_of_year() }

    defp before_min_date_with_same_years(true, min_date_month), do: min_date_month === 12
    defp before_min_date_with_same_years(_, _min_date_month), do: false

    defp after_max_date_with_same_years(true, max_date_month), do: max_date_month === 1
    defp after_max_date_with_same_years(_, _max_date_month), do: false

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
end

defmodule Phoenix.Components.DatePicker do
  defmodule Response do
    defstruct [:target, :value_str, :date, :range]
  end

  @moduledoc """
  Documentation for DatePicker.
  """
  use Phoenix.LiveComponent

  use Timex
  require Logger

  alias Timex.Timezone
  alias Phoenix.Components.DatePicker.Helpers.{Range, Calendar}
  alias Phoenix.Components.{CalendarDay, CalendarMonthYear}


  @week_start_at :mon

  @tz_default Timezone.name_of(0)

  @default_data %{
    value: nil,
    range_selected: nil,
    show_calendar: false,
    right_month: Timex.now(),
    start_date: nil,
    end_date: nil,
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
     |> assign(label: nil)
     |> assign(field_name: "field_date")
     |> assign(min_date: nil)
     |> assign(max_date: nil)
     |> assign(single_picker?: true)
     |> assign(placeholder: "Seleccione")
     |> assign(custom_range?: false)
     |> assign(ranges: [])
     |> assign(selection_class: "blue-600")
     |> assign(selection_hover_class: "blue-400")
     |> assign(day_names: day_names(@week_start_at))
     |> assign(left_month: Timex.now() |> Timex.shift(months: -1))
    }
  end

  def update(assigns, socket) do
    {:ok,
      socket
        |> assign(assigns)
        |> set_data()
        |> set_time_zone()
        |> set_min_date()
        |> set_max_date()
        |> set_ranges()
        |> update_picker()
    }
  end

  defp set_data(%{assigns: %{value: value, range_selected: range_selected}} = socket)
       when value == nil and range_selected != nil,
       do: socket |> assign(range_selected: nil) |> assign(show_calendar: false)

  defp set_data(socket), do: socket

  defp set_time_zone(%{assigns: %{tz_offset: tz_offset}} = socket),
    do: socket |> assign(time_zone: tz_offset |> Calendar.get_time_zone() |> ok_time_zone())

  defp set_time_zone(socket), do: socket |> assign(time_zone: @tz_default)

  defp ok_time_zone(time_zone) do
    if Timex.is_valid_timezone?(time_zone), do: time_zone, else: @tz_default
  end

  defp set_min_date(%{assigns: %{time_zone: time_zone}} = socket),
    do: socket |> assign(:min_date, Calendar.one_hundred_years_ago(time_zone))

  defp set_min_date(socket), do: socket

  defp set_max_date(%{assigns: %{time_zone: time_zone}} = socket),
    do: socket |> assign(:max_date, Calendar.one_hundred_years_after(time_zone))

  defp set_max_date(socket), do: socket

  defp set_ranges(%{assigns: %{single_picker?: false}} = socket),
    do: socket |> ranges_definitions()

  defp set_ranges(socket), do: socket

  defp update_picker(
         %{
           assigns: %{
            single_picker?: true,
            time_zone: time_zone,
            current_month: current_month
           }
         } = socket
       ) do
    current_month = current_month |> Timezone.convert(time_zone)

    socket
    |> assign(:current_month, current_month)
    |> assign(:week_rows, week_rows(current_month))
  end

  defp update_picker(
         %{
           assigns: %{
            single_picker?: false,
            time_zone: time_zone,
            left_month: left_month,
            right_month: right_month
           }
         } = socket
       ) do
    right_month = right_month |> Timezone.convert(time_zone) |> Timex.beginning_of_month()

    left_month = left_month |> Timezone.convert(time_zone) |> Timex.beginning_of_month()

    socket |> set_values_to_picker(left_month, right_month)
  end

  defp update_picker(socket), do: socket

  def handle_event("clear", _, %{assigns: %{time_zone: time_zone}} = socket) do
    {:noreply,
     socket
     |> assign(@default_data)
     |> assign(left_month: Calendar.now(time_zone) |> Timex.shift(months: -1))
     |> update_picker()
     |> response()
    }
  end

  def handle_event("toogle_calendar_mode", %{"calendar" => "left"}, %{assigns: %{calendar_left_mode: mode}} = socket) do
    {:noreply, socket |> assign(calendar_left_mode: toogle_calendar_mode(mode))}
  end

  def handle_event("toogle_calendar_mode", %{"calendar" => "right"}, %{assigns: %{calendar_right_mode: mode}} = socket) do
    {:noreply, socket |> assign(calendar_right_mode: toogle_calendar_mode(mode))}
  end

  def handle_event("toogle_calendar_mode", _, %{assigns: %{calendar_mode: mode}} = socket) do
    {:noreply, socket |> assign(calendar_mode: toogle_calendar_mode(mode))}
  end

  def handle_event("prev", %{"calendar" => "left"},
    %{assigns: %{ calendar_left_mode: mode, left_month: month, min_date: min_date }} = socket) do

    temporal_month = previous_date(mode, month, min_date)

    {:noreply,
      socket
      |> assign(left_month: temporal_month)
      |> assign(week_rows_left: week_rows(temporal_month))
    }
  end

  def handle_event("prev", %{"calendar" => "right"},
    %{assigns:
      %{ calendar_right_mode: mode, left_month: left_month, right_month: right_month}} = socket) do

    temporal_month = previous_date(mode, right_month, left_month |> Timex.shift(months: 1))

    {:noreply,
      socket
      |> assign(right_month: temporal_month)
      |> assign(week_rows_right: week_rows(temporal_month))
    }
  end

  def handle_event("prev", _,
    %{assigns: %{ calendar_mode: mode, current_month: month, min_date: min_date }} = socket) do
    temporal_month = previous_date(mode, month, min_date)

    {:noreply,
      socket
      |> assign(current_month: temporal_month)
      |> assign(week_rows: week_rows(temporal_month))
    }
  end

  def handle_event("next", %{"calendar" => "left"},
    %{assigns: %{ calendar_left_mode: mode, left_month: left_month, right_month: right_month }} = socket) do

    temporal_month = next_date(mode, left_month, right_month |> Timex.shift(months: -1))

    {:noreply,
      socket
      |> assign(left_month: temporal_month)
      |> assign(week_rows_left: week_rows(temporal_month))
    }
  end

  def handle_event("next", %{"calendar" => "right"},
    %{assigns: %{ calendar_right_mode: mode, right_month: month, max_date: max_date }} = socket) do

    temporal_month = next_date(mode, month, max_date)

    {:noreply,
      socket
      |> assign(right_month: temporal_month)
      |> assign(week_rows_right: week_rows(temporal_month))
    }
  end

  def handle_event("next", _,
    %{assigns: %{ calendar_mode: mode, current_month: month, max_date: max_date }} = socket) do

    temporal_month = next_date(mode, month, max_date)

    {:noreply,
      socket
      |> assign(current_month: temporal_month)
      |> assign(week_rows: week_rows(temporal_month))
    }
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

  def handle_event("range_option_selected", %{"key" => key}, %{assigns: %{range_options: range_options}} = socket) do
    range_selected = range_options |> Enum.find(fn %{key: k} -> k == key end)
    {:noreply,
      socket
      |> assign(:range_selected, range_selected)
      |> update_value_by_selection()
    }
  end

  def handle_event("pick-date", %{"block" => "true"}, socket) do
    {:noreply, socket}
  end

  def handle_event("pick-date", %{"date" => date}, %{assigns: %{single_picker?: true}} = socket) do
    {:noreply,
      socket
      |> assign(:current_date, Timex.parse!(date, "%FT%T", :strftime))
      |> response()
    }
  end

  def handle_event("pick-date", %{"date" => date}, %{
    assigns: %{
     single_picker?: false}} = socket) do
    {:noreply, socket |> set_custom_range(Timex.parse!(date, "%FT%T", :strftime))}
  end

  defp toogle_calendar_mode(:date), do: :month
  defp toogle_calendar_mode(:month), do: :year
  defp toogle_calendar_mode(_), do: :date

  # PREV DATES
  defp previous_date(:month, current_month, min_date) do
    if min_date != nil do
      diff = Timex.diff(current_month, min_date, :months)

      if diff > 12,
        do: Timex.shift(current_month, years: -1),
        else: min_date
    else
      Timex.shift(current_month, years: -1)
    end
  end

  defp previous_date(:year, current_month, min_date) do
    if min_date != nil do
      diff = Timex.diff(current_month, min_date, :months)

      if diff > 120,
        do: Timex.shift(current_month, years: -10),
        else: min_date
    else
      Timex.shift(current_month, years: -10)
    end
  end

  defp previous_date(_mode, current_month, min_date) do
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
  defp next_date(:month, current_month, max_date) do
    if max_date != nil do
      diff = Timex.diff(max_date, current_month, :months)

      if diff > 12,
        do: Timex.shift(current_month, years: 1),
        else: max_date
    else
      Timex.shift(current_month, years: 1)
    end
  end

  defp next_date(:year, current_month, max_date) do
    if max_date != nil do
      diff = Timex.diff(max_date, current_month, :months)

      if diff > 120,
        do: Timex.shift(current_month, years: 10),
        else: max_date
    else
      Timex.shift(current_month, years: 10)
    end
  end

  defp next_date(_calendar_mode, current_month, max_date) do
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
  defp update_value_by_selection(%{assigns: %{range_selected: nil}} = socket), do: socket

  defp update_value_by_selection(%{assigns: %{range_selected: %Range{key: "custom"}}} = socket) do
    time_zone = socket.assigns.time_zone
    right_month = Calendar.now(time_zone) |> Timex.beginning_of_month()
    left_month = right_month |> Timex.shift(months: -1) |> Timex.beginning_of_month()

    socket
      |> set_values_to_picker(left_month, right_month)
      |> assign(:show_calendar, true)
      |> assign(:start_date, nil)
      |> assign(:end_date, nil)
  end

  defp update_value_by_selection(socket),
    do:
      socket
        |> assign(:show_calendar, false)
        |> response()

  # SELECT A CUSTOM RANGE
  defp set_custom_range(%{assigns: %{start_date: sd, end_date: ed, range_selected: rs}} = socket, date) when sd != nil and ed != nil do
    socket
    |> assign(:start_date, date)
    |> assign(:end_date, nil)
    |> assign(:range_selected, %{rs | interval: nil, value: nil})
  end

  defp set_custom_range(%{assigns: %{start_date: sd, range_selected: rs}} = socket, date) when is_nil(sd) do
    socket
    |> assign(:start_date, date)
    |> assign(:range_selected, %{rs | interval: nil, value: nil})
  end

  defp set_custom_range(%{assigns: %{time_zone: time_zone, start_date: start_date, range_selected: rs}} = socket, date) do
    end_date = date |> Timex.end_of_day() |> Timezone.convert(time_zone)

    if start_date |> Timex.before?(end_date) do
      new_interval =
        Timex.Interval.new(from: start_date, until: end_date, right_open: false)

      values =
        Timex.format!(start_date, "{0D}/{0M}/{YYYY}") <> " - " <> Timex.format!(end_date, "{0D}/{0M}/{YYYY}")

      socket
      |> assign(:end_date, end_date)
      |> assign(:range_selected, %{rs | interval: new_interval, value: values})
      |> response()
    else
      socket |> assign(:start_date, date)
    end
  end

  # RESPONSE
  defp response(%{assigns: %{field_name: target, range_selected: range}} = socket) when range != nil do
    send(self(),
      {
        __MODULE__,
        :picker_changed,
        %Response{
          target: target,
          value_str: range.value,
          range: range.interval
        }
      })
    socket
  end

  defp response(%{assigns: %{field_name: target, current_date: date}} = socket) when date != nil do
    send(self(),
      {
        __MODULE__,
        :picker_changed,
        %Response{
          target: target,
          value_str: date |> Timex.format!("{0D}/{0M}/{YYYY}"),
          date: date
        }
      })
    socket
  end

  defp response(%{assigns: %{field_name: target}} = socket) do
    send(self(), {__MODULE__, :picker_changed, %Response{target: target}})
    socket
  end

  defp response(socket), do: socket

  defp set_values_to_picker(socket, left_month, right_month) do
    socket
    |> assign(:left_month, left_month)
    |> assign(:right_month, right_month)
    |> assign(:week_rows_left, week_rows(left_month))
    |> assign(:week_rows_right, week_rows(right_month))
  end


  def default_ranges(time_zone), do: Range.defaults(Calendar.now(time_zone))

  defp custom_range(), do: [Range.custom("Personalizado")]

  # Definir rangos por defecto sin el rango custom
  def ranges_definitions(
        %{assigns: %{time_zone: time_zone, ranges: [], custom_range?: false}} = socket
      ) do
    socket |> assign(range_options: default_ranges(time_zone))
  end
  # Definir rangos por defecto con el rango custom
  def ranges_definitions(%{assigns: %{time_zone: time_zone, ranges: []}} = socket) do
    socket |> assign(range_options: default_ranges(time_zone) ++ custom_range())
  end
  # Construir rangos segun configuracion del componente
  def ranges_definitions(
        %{assigns: %{time_zone: time_zone, ranges: ranges, custom_range?: custom_range}} = socket
      ) do
    socket |> assign(range_options: build_ranges(ranges, time_zone, custom_range))
  end
  # Definir rangos por defecto con el rango custom
  def ranges_definitions(%{assigns: %{time_zone: time_zone}} = socket) do
    Logger.debug("La definición de rangos no se pudo determinar. La opciones de rango toman los valores por defecto.")
    socket |> assign(range_options: default_ranges(time_zone) ++ custom_range())
  end

  defp build_ranges(ranges, time_zone, custom_range) when is_list(ranges) do
    ranges
    |> Enum.map(&(Range.new(&1, Calendar.now(time_zone))))
    |> Enum.reject(&nil_range/1)
    |> case do
      [] ->
        Logger.debug("La definición de rangos no se pudo determinar. La opciones de rango toman los valores por defecto.
        #{inspect(ranges)}"
      )
        default_ranges(time_zone)

      r ->
        #Por cuestiones de dinsenno solo tomamos 7 rangos de los que se especifiquen
        r |> Enum.take(7) |> add_custom_range(custom_range)
    end
  end

  defp build_ranges(ranges, time_zone, _custom_range) do
    Logger.debug(
      "La declaracion de rangos, no cumple con la especificacion definida para el componente.
      #{inspect(ranges)}"
    )

    default_ranges(time_zone)
  end

  defp nil_range(nil), do: true
  defp nil_range(_), do: false

  defp add_custom_range(r, true), do: r ++ custom_range()
  defp add_custom_range(r, _), do: r

  defp day_names(:mon), do: [1, 2, 3, 4, 5, 6, 7] |> Enum.map(&Calendar.days_of_week/1)
  defp day_names(_), do: [7, 1, 2, 3, 4, 5, 6] |> Enum.map(&Calendar.days_of_week/1)

  # ----> HTML HELPER FUNCTIONS <----
  defp generate_id_calendar(parent_id, calendar, date) do
    date_format = date |> Timex.format!("%m/%d/%Y", :strftime)

    case calendar do
      "left" -> "#{parent_id}_left_month-#{date_format}"
      _ -> "#{parent_id}_right_month-#{date_format}"
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

  defp get_header_title(date, calendar_mode) do
    case calendar_mode do
      :month ->
        Timex.format!(date, "%Y", :strftime)

      :year ->
        range_years = create_10_years_range(date, 0, 9) |> Enum.to_list()
        "#{List.first(range_years)} - #{List.last(range_years)}"

      _ ->
        month = Timex.format!(date, "%B", :strftime) |> Timex.month_to_num() |> Calendar.sp_month()
        year = Timex.format!(date, "%Y", :strftime)
        "#{month} #{year}"
    end
  end

  defp create_10_years_range(date, minus_offset, plus_offset) do
    current_year = date |> Map.take([:year]) |> Map.get(:year)
    temporal_rem = current_year |> rem(10)
    (current_year - temporal_rem - minus_offset)..(current_year + plus_offset - temporal_rem)
  end

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

    {new_first, new_last} = values_for_interval(month, first, last, diff)

    Interval.new(from: new_first, until: new_last)
    |> Enum.map(& &1)
    |> Enum.chunk_every(7)
  end

  defp values_for_interval(month, first, last, 4) do
    diff_first = Timex.diff(month |> Timex.beginning_of_month(), first)
    diff_last = Timex.diff(last, month |> Timex.end_of_month())

    if diff_first <= diff_last do
      {first |> Timex.shift(weeks: -1), last}
    else
      {first, last |> Timex.shift(weeks: 1)}
    end
  end

  defp values_for_interval(_month, first, last, 3) do
    {first |> Timex.shift(weeks: -1), last |> Timex.shift(weeks: 1)}
  end

  defp values_for_interval(_month, first, last, _diff) do
    {first, last}
  end

  defp is_custom_range?(%Range{key: "custom"}), do: true
  defp is_custom_range?(_), do: false


  defp get_range_class(nil, _, _, hover_class), do: "hover:bg-#{hover_class}"

  defp get_range_class(%Range{key: sk}, %Range{key: k}, _, hover_class) when sk != k,
    do: "hover:bg-#{hover_class}"

  defp get_range_class(_, _, class, _),
  do: "text-white bg-#{class} hover:bg-#{class} border-#{class} hover:border-#{class}"

end
