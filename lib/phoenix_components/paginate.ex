defmodule Phoenix.Components.Paginate do
  @moduledoc """
  Documentation for Paginate.
  """
  use Phoenix.LiveComponent

  # Configurando parametros por defecto
  @defaults %{records: [], total_records: 0, total_page: 0, options: %{page: 1, per_page: 10, sort: "inserted_at:desc"}}

  # Cargar pagina con los parametros de la url, por defecto toma @defaults
  def handleparams(data, params, socket), do: to_merge(data, params) |> process_params(socket)

  # Para eventos donde se modifica page y per_page en la url
  def handleevent(socket, routes, route, params) do
    options =
      %{page: params["page"] |> to_integer,
        per_page: params["per_page"] |> to_integer
       }

    map =
      Map.take(socket.assigns, [:total_records, :total_page])
      |> Enum.into(%{options: options})

    push_patch(socket,
        to:
          routes.live_path(
            socket,
            route,
            page: valida_page(map),
            per_page: map.options.per_page
        )
      )
  end

  # Verifica que la pagina sea mayor a 0
  defp process_params(%{options: %{page: page} = options} = params, socket) when is_integer(page) and page < 1, do: apply_params(%{params | options: %{options | page: 1}}, socket)
  defp process_params(%{options: %{page: page}} = params, socket) when is_integer(page), do: apply_params(params, socket)
  defp process_params(%{options: %{page: page} = options} = params, socket) when is_binary(page), do: %{params | options: %{options | page: to_integer(page)}} |> process_params(socket)
  defp process_params(_, socket), do: socket

  # Convierte params a atom y devuelve objeto para usarse en la vista
  defp apply_params(params, socket) do
    assign(socket,
      options: %{page: to_integer(params.options.page), per_page: to_integer(params.options.per_page)},
      records: params.records,
      total_records: params.total_records,
      total_page: params.total_page
    )
  end

  # Mezclado con @defaults.options por si no existen parametros en la url
  defp to_merge(data, params) do
    options =
      params
      |> Enum.map(fn ({key, val}) -> {String.to_atom(key), val} end)
      |> Enum.into(%{})

    Map.merge(@defaults, data)
    |> update_in([:options], &Map.merge(&1, options))
    |> update_total()
  end

  # Actualiza total de paginas
  defp update_total(params), do: %{params | total_page: total(params)}

  # Valida el defase de paginas al cambiar cantidad elementos por pagina
  defp valida_page(%{options: %{page: page, per_page: per_page}} = params) when ceil((page * per_page) / per_page) > ceil(params.total_records/per_page), do: total(params)
  defp valida_page(params), do: params.options.page

  # Calcula total paginas
  defp total(num_total, per_page), do: ceil(num_total/to_integer(per_page))
  defp total(%{total_records: num_total, options: %{per_page: per_page}}), do: total(num_total, per_page)

  # Convierte a entero el parametro
  defp to_integer(num) when is_integer(num), do: num
  defp to_integer(num) when is_binary(num), do: String.to_integer(num)
  defp to_integer(_), do: 1

  # Deshabilitando el paginador
  defp isdisabled(true), do: "text-gray-300 bg-gray-50 border-gray-300 pointer-events-none"
  defp isdisabled(_), do: ""
end
