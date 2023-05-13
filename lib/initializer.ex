defmodule MessageBroker.Initializer do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :auth)
  end

  def init(_opts) do
    {:ok, %{}}
  end

  def init_role_prompt(socket) do
    if MessageBroker.RoleManager.has_role?(socket) == false do
      MessageBroker.TerminalHandler.write_line(socket, {:ok, "Do you wish to be a Publisher or Subscriber? PUB/SUB"})

      msg =
        with {:ok, data} <- MessageBroker.TerminalHandler.read_line(socket),
        {:ok, role} <- MessageBroker.RoleManager.assign(socket, String.trim(data)),
        do: finish_role_prompt(socket, role)

      MessageBroker.TerminalHandler.write_line(socket, msg)
      case msg do
        {:error, :unknown, _} -> init_role_prompt(socket)
        {:ok, _} -> MessageBroker.CommandHandler.prompt_command(socket)
      end
    end
  end

  def finish_role_prompt(socket, role) do
    case role do
      :consumer ->
        {:ok, "Successfully assigned role."}
      :producer ->
        MessageBroker.TerminalHandler.write_line(socket, {:ok, "Please enter a publisher name:"})
        with {:ok, name} <- MessageBroker.TerminalHandler.read_line(socket),
        :ok <- MessageBroker.SubscriptionManager.register_publisher(socket, String.trim(name)),
        do: {:ok, "Successfully assigned role and name."}
    end
  end
end
