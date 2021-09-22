# PhoenixComponents

**TODO: Agregar descripcion**

## Instalacion


```elixir
def deps do
  [
    {:phoenix_components, git: "https://bitbucket.org/teamdox/phoenix_components"}
  ]
end
```

## Phoenix.Components.DatePicker

El componente **DatePicker** está diseñado para poder seleccionar una fecha o un rango de fecha. Permite la navegación del calendario por meses y por años. Tiene una navegación de 200 años, tomando como punto de partida la fecha actual(100 años <= hoy >= 100 años). Se utiliza Tailwind para el estilo del componente y Timex para las funciones de fecha.

Agregar lo siguiente en el modulo:
### Dependencias
```elixir
defp deps do
  [
    {:timex, "~> 3.7.6"}
  ]
```
### Configuracion
* `alias Phoenix.Components.DatePicker`
* `alias Phoenix.Components.DatePicker.Response`

* Eg. del `handle_info`:
  ```elixir
    def handle_info({DatePicker, :picker_changed, %Response{target: target, value_str: value, :date, :range}}, socket)
  ```
##### Estructura **Response**
* `target` identifica el nombre del input que contiene la fecha o el rango de fecha
* `value_str` valor del input que contiene la fecha o el rango seleccionado.
* `date` Fecha seleccionada(`Datetime` ajustado al localtime del navegador), toma valor `nil` si estas en modo Rango.
* `range` Rango de fecha seleccionado(Estructura `Timex.Interval` ajustado al localtime del navegador), toma valor `nil` si estas en modo Simple.


* Integración en la vista para un DatePicker Simple.

```elixir
  <%= live_component @socket, DatePicker,
    id: :unique_id,
    field_name: "inserted_at",
    value: @inserted_at,
    label: "Fecha inicio",
    placeholder: "Fecha de inicio",
    tz_offset: -4,
    selection_class: "primary-200"
  %>
```
* Integración en la vista para un DatePicker de Rango.

```elixir
  <%= live_component @socket, DatePicker,
    id: :unique_id,
    field_name: "inserted_at",
    value: @inserted_at,
    label: "Fecha inicio",
    placeholder: "Seleccione un rango",
    tz_offset: -4,
    selection_class: "primary-200",
    selection_hover_class: "primary-300",
    single_picker?: false,
    custom_range?: true,
    ranges: [:today, :yesterday, %{label: "Ultimos 5 años", amount: -5, in: :years}]
  %>
```

* `id` Especificar un id diferente en cada lugar que se use el componente
* `field_name` Nombre del input en html.
* `value` Se corresponde con el valor que se muestra en el input.
* `label` Si deseas agregarle en html un label al componente, aqui especificas el texto del label.
* `placeholder` Especificas un placeholder al elemento input. Por defecto tiene el valor `Seleccione`
* `tz_offset` Numero que identifica el `time_zone_offset`, por defecto es 0
* `selection_class` Variante Tailwind para cambiar el background de las selecciones en el componente.
* `selection_hover_class` Solo es necesario cuando el DatePicker es de Rango. Se utiliza para cambiar la clase `hover` de los elementos que estan dentro del rango que se selecciona y en las opciones de los rangos predeterminados.
* `single_picker?` Especificar el tipo de DatePicker (`true` -> Simple, `false` -> Rango). Por defecto es `true`.
* `custom_range?` Este valor es solo tomado en cuenta si `single_picker?` tiene valor `false`. En dependencia de su valor(`true` o `false`), se agrega al listado de rangos la opcion para seleccionar un rango personalizado. Por defecto tiene valor `false`
* `ranges` Se espera que sea un listado de rangos que quisiera definir. De no especificar ningun valor, el componente toma los rangos por defectos para darle la opcion de que tenga rangos personalizados. A continuacion se especifican como definir los rangos personalizados.


### Rangos
#### Por defecto
El componente tiene los siguientes Rangos definidos y que usted puede usar sin tener que especificarlo en la configuracion del mismo.
```elixir
today: "Hoy",
yesterday: "Ayer",
last_7days: "Últimos 7 días", # Se incluye el dia de hoy como parte del rango
last_30days: "Últimos 30 días", # Se incluye el dia de hoy como parte del rango
this_month: "Mes actual",
last_month: "Mes pasado",
this_year: "Año actual"
```
#### Definir un rango
Se puede hacer de dos manera.
* Si deseas usar uno definido por el componente solo debes especificar una de las key de las antes mencionadas. Eg. `:today` o `:last_30days`
* Puedes definir uno completamente nuevo, para ello defines un mapa con la siguiente estructura.
Eg. `%{label: "Ultimos 5 años", amount: -5, in: :years}`,
Eg. `%{label: "Mañana", amount: 1, in: :days}`,
se espera que `label` es una cadena, `amount` un entero, `in` un atom (`:days`, `:months`, `:years`)
