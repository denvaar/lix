defmodule Lix.Consumer do
  use GenServer

  @name __MODULE__

  ## Cli

  def start_link(_args) do
    GenServer.start_link(__MODULE__, {}, name: @name)
  end

  def init(_args) do
    {:ok, {}}
  end

  def get_message(queue) do
    GenServer.call(@name, {:get_message, queue})
  end

  def delete_message(queue_url, receipt_handle) do
    GenServer.cast(@name, {:delete_message, queue_url, receipt_handle})
  end

  defp parse_messages(%{body: %{messages: messages}}) do
    messages
  end

  ## OTP callbacks

  def handle_call({:get_message, queue}, _from, _state) do
    messages =
      ExAws.SQS.receive_message("queue/#{queue}")
      |> ExAws.request!()
      |> parse_messages

    {:reply, messages, queue}
  end

  def handle_cast({:delete_message, queue, receipt_handle}, state) do
    ExAws.SQS.delete_message("queue/#{queue}", receipt_handle)
    |> ExAws.request!()

    {:noreply, state}
  end
end
