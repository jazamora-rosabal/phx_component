defmodule Phoenix.Components do
  @moduledoc """
  Funciones de ayuda para el uso de componentes Phoenix Liveview

  Para importar los modulos o componentes:
    * `Phoenix.Components` - funciones de ayudas;

    * `Phoenix.Components.Paginate` - para trabajar con paginador;

    * `Phoenix.Components.Viewer` - para listar/visualizar documentos pdf;

  """

  @doc false
  defmacro __using__(_) do
    quote do
      import Phoenix.Components
      import Phoenix.Components.Paginate
      import Phoenix.Components.Viewer
      import Phoenix.Components.DatePicker
    end
  end

  # Formatea la fecha
  def formatdate(date), do: "#{date.day}/#{date.month}/#{date.year}"

  # Extract date from iso8601
  def convert_date(iso8601), do: NaiveDateTime.from_iso8601(iso8601) |> extractdate

  # Muestra barra progresso
  # default => assign(:progress, %{:total => 0, :loaded => 0})
  def progressbar(%{:total => 0, :loaded => 0}), do: "width: 0"

  def progressbar(%{:total => total, :loaded => loaded}),
    do: "width: #{(loaded / total * 100) |> trunc()}%"

  # Extraer la fecha
  defp extractdate({:ok, date}), do: date
  defp extractdate(_), do: DateTime.utc_now()
end
