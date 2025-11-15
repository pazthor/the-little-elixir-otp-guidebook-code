defmodule ChatApp.Application do
  use Application

  @moduledoc """
  The ChatApp application supervisor.

  Starts the supervision tree with registries for users and rooms,
  and dynamic supervisors for managing user and room processes.
  """

  def start(_type, _args) do
    children = [
      # Registries for process name lookups
      {Registry, keys: :unique, name: ChatApp.UserRegistry},
      {Registry, keys: :unique, name: ChatApp.RoomRegistry},

      # Dynamic supervisors for users and rooms
      {DynamicSupervisor, strategy: :one_for_one, name: ChatApp.UserSupervisor},
      {DynamicSupervisor, strategy: :one_for_one, name: ChatApp.RoomSupervisor}
    ]

    opts = [strategy: :one_for_one, name: ChatApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
