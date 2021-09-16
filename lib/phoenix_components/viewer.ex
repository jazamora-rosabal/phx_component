defmodule Phoenix.Components.Viewer do
  @moduledoc """
  Documentation for Viewer.
  """
  use Phoenix.LiveComponent
  import Phoenix.Components

  @impl true
  def mount(socket) do
    {:ok,
      socket
      |> assign(:id, :viewer)
      |> assign(:selected, nil)
    }
  end

  @impl true
  def handle_event("selected", %{"selected" => selected}, socket) do
    {:noreply, assign(socket, :selected, selected)}
  end
end
