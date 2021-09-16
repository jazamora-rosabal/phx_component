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

## Phoenix.Components.Paginate

Agregar lo siguiente en el modulo:

* `alias Phoenix.Components.Paginate`
* Eg. del `handle_params`:
  ```elixir
    @impl true
    def handle_params(params, _url, socket) do
      page = params["page"] || 1
      perpage = params["per_page"] || 10

      {:noreply,
      Expedientes.search_m(page, perpage, "solicitud_servicio")
      |> Expedientes.clean_monad_records()
      |> Paginate.handleparams(params, socket)
      }
    end
  ```

* Eg. del `handle_event`:
  ```elixir
    def handle_event("change", params, socket), do: {:noreply, Paginate.handleevent(socket, Routes, __MODULE__, params)}
  ```

* Integración en la vista.

```elixir
  <%= live_component @socket,
    Paginate,
    id: :paginatehome,
    options: @options,
    total_records: @total_records,
    total_page: @total_page,
    options_select: [5, 10, 15, 20, 100],
    routes: Routes,
    route: __MODULE__
  %>
```

* `id` especificar un id diferente en cada lugar que se use el componente
* `options` se espera que sea un mapa `%{page: page, per_page: per_page, sort: sort}` que puede estar en blanco por defecto.
* `total_records` total de registros
* `total_page` total de paginas
* `options_select` listado de elementos por pagina
* `routes` para acceder a las rutas de la app
* `route` ruta de la pagina actual

### Modulos usados para expedientes y búsqueda en alberto

* [Expedientes](https://bitbucket.org/teamdox/servicio_solicitud/src/development/lib/solicitudservicios/expedientes.ex)
* [Search](https://bitbucket.org/teamdox/servicio_solicitud/src/development/lib/solicitudservicios/search.ex)


## Phoenix.Components.Viewer

* Integración en la vista.

```elixir
  <%= live_component @socket,
    Phoenix.Components.Viewer,
    id: :viewer,
    node: @node
  %>
```

* `id` especificar un id diferente en cada lugar que se use el componente
* `node` se espera que sea un mapa `%{selected: selected, children: children.records}`
