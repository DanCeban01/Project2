defmodule MessageBroker.Application do
  use Application
  require Logger

  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "4040")

    children = [
      MessageBroker.TerminalHandler,
      MessageBroker.Initializer,
      MessageBroker.RoleManager,
      MessageBroker.SubscriptionManager,
      {Task.Supervisor, name: MessageBroker.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> accept(port) end}, restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: MessageBroker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info "Accepting connections on port #{port}"
    loop_listener(socket)
  end

  defp loop_listener(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(MessageBroker.TaskSupervisor, fn -> MessageBroker.Initializer.init_role_prompt(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_listener(socket)
  end
end
