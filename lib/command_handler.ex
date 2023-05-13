defmodule MessageBroker.CommandHandler do

  def prompt_command(socket) do
    msg =
      with {:ok, data} <- MessageBroker.TerminalHandler.read_line(socket),
           {:ok, command} <- parse(data),
           do: execute(socket, command)

    MessageBroker.TerminalHandler.write_line(socket, msg)
    prompt_command(socket)
  end

  def parse(line) do
    data = String.trim(line)
    parts = String.split(data, "|")

    case parts do
      ["SUB" | [topic]] -> {:ok, {:subscribe_topic, String.trim(topic)}}
      ["SUB@" | [name]] -> {:ok, {:subscribe_publisher, String.trim(name)}}
      ["PUB" | [topic, message]] -> {:ok, {:publish, String.trim(topic), String.trim(message)}}
      _ -> {:error, :unknown, "command #{inspect data}."}
    end
  end

  def execute(client, {:subscribe_topic, topic}) do
    if MessageBroker.RoleManager.check_role(client, :consumer) do
      status = MessageBroker.SubscriptionManager.subscribe_to_topic(client, topic)
      case status do
        :ok -> {:ok, "Subscribed to topic: #{inspect topic}."}
        _ -> status
      end
    else
      {:error, :unauthorized, "subscribe"}
    end
  end

  def execute(client, {:subscribe_publisher, name}) do
    if MessageBroker.RoleManager.check_role(client, :consumer) do
      status = MessageBroker.SubscriptionManager.subscribe_to_publisher(client, name)
      case status do
        :ok -> {:ok, "Subscribed to publisher: #{inspect name}."}
        _ -> status
      end
    else
      {:error, :unauthorized, "subscribe"}
    end
  end

  def execute(client, {:publish, topic, message}) do
    if MessageBroker.RoleManager.check_role(client, :producer) do
      status = MessageBroker.SubscriptionManager.publish(client, topic, message)
      case status do
        :ok -> {:ok, "Published message #{inspect message} to topic: #{inspect topic}."}
        _ -> status
      end
    else
      {:error, :unauthorized, "publish"}
    end
  end
end
