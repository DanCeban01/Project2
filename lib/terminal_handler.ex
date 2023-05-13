defmodule MessageBroker.TerminalHandler do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :terminal_handler)
  end

  def init(_opts) do
    {:ok, %{}}
  end

  def read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp send_client(socket, text) do
    :gen_tcp.send(socket, "#{text}\r\n")
  end

  def write_line(socket, {:ok, text}) do
    send_client(socket, text)
  end

  def write_line(socket, {:error, :unknown, reason}) do
    send_client(socket, "Unknown #{reason}")
  end

  def write_line(socket, {:error, :unauthorized, action}) do
    send_client(socket, "Unauthorized: As a #{MessageBroker.RoleManager.get_role_name(socket)} you don't have permission to #{action}.")
  end

  def write_line(socket, {:error, :sub_manager, reason}) do
    case reason do
      :already_subscribed -> send_client(socket, "Already subscribed to the topic.")
      :publisher_not_found -> send_client(socket, "No such Publisher found. Please check your spelling.")
      :already_subscribed_to_publisher -> send_client(socket, "Already subscribed to this Publisher.")
      _ -> write_line(socket, {:error, reason})
    end
  end

  def write_line(_socket, {:error, :closed}) do
    exit(:shutdown)
  end

  def write_line(socket, {:error, error}) do
    send_client(socket, "Error #{inspect error}")
    exit(error)
  end
end
