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

### Dependencias
```elixir
defp deps do
  [
    {:timex, "~> 3.7.6"}
  ]
```
### Configuracion
En tu proceso LiveView colocas lo siguiente:

* `alias Phoenix.Components.DatePicker`
* `alias Phoenix.Components.DatePicker.Response`

* Eg. del `handle_info`:
  ```elixir
    def handle_info({DatePicker, :picker_changed, %Response{target: target, value_str: value, :date, :range}}, socket)
  ```
#### Estructura **Response**
* `target` identifica el nombre del input que contiene la fecha o el rango de fecha
* `value_str` valor del input que contiene la fecha o el rango seleccionado.
* `date` Fecha seleccionada(`Datetime` ajustado al localtime del navegador), toma valor `nil` si estas en modo Rango.
* `range` Rango de fecha seleccionado(Estructura `Timex.Interval` ajustado al localtime del navegador), toma valor `nil` si estas en modo Simple.
##### Eg. **Response** para una fecha simple(tz_offset: -4)
```elixir
 %Phoenix.Components.DatePicker.Response{
  target: "inserted_ot",
  value_str: "19/08/2021",
  date: ~N[2021-08-19 04:00:00],
  range: nil
}
```
##### Eg. **Response** para un rango de fecha(tz_offset: -4)
```elixir
 %Phoenix.Components.DatePicker.Response{
  target: "inserted_at",
  value_str: "16/09/2021 - 22/09/2021",
  range: %Timex.Interval{
    from: ~N[2021-09-16 04:00:00.000000],
    left_open: false,
    right_open: false,
    step: [days: 1],
    until: ~N[2021-09-23 03:59:59.999999]
  },
  date: nil
}
```


**Integración en la vista para un DatePicker Simple.**

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
**Integración en la vista para un DatePicker de Rango.**

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
* `field_name` Nombre del input en HTML(Se corresponde con el valor de `target` en la estructura **Response**).
* `value` Se corresponde con el valor que se muestra en el input.
* `label` Agrega en HTML un label al componente.
* `placeholder` Especificar un placeholder al elemento input. Por defecto tiene el valor `Seleccione`
* `tz_offset` Numero que identifica el `time_zone_offset` del navegador, por defecto es 0
* `selection_class` Variante Tailwind para cambiar el background de las selecciones en el componente.
* `selection_hover_class` Solo es necesario cuando el DatePicker es de Rango. Se utiliza para cambiar la clase `hover` de los elementos que están dentro del rango que se selecciona y en las opciones de los rangos predeterminados.
* `single_picker?` Especifica el tipo de DatePicker (`true` -> **Simple**, `false` -> **Rango**). Por defecto es `true`.
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
* Si deseas usar uno definido por el componente solo debes especificar una **key** de las antes mencionadas.
Eg.
```elixir
<%= live_component @socket, DatePicker,
    ranges: [:today, :yesterday]
 %>
```
* Puedes definir uno completamente nuevo, para ello defines un mapa con la siguiente estructura.
`%{label: label, amount: amount, in: :step}`
se espera que `label` es una cadena, `amount` un entero, `in` un atom (`:days`, `:months`, `:years`)
Eg.
```elixir
<%= live_component @socket, DatePicker,
    ranges:
    [
      :today, # Puedes convinar ambas configuraciones.
      %{label: "Mes próximo", amount: 1, in: :months},
      %{label: "Ultimos 5 años", amount: -5, in: :years}
    ]
 %>
```
