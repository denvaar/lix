defmodule Lix.Consumer do
  use GenServer

  @name __MODULE__

  ## Consumer API

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

  defp max_number_of_messages do
    Application.fetch_env!(:lix, :max_number_of_messages)
  end

  defp visibility_timeout do
    Application.fetch_env!(:lix, :visibility_timeout)
  end

  ## Consumer OTP callbacks

  def handle_call({:get_message, queue}, _from, _state) do
    messages =
      ExAws.SQS.receive_message(queue,
        max_number_of_messages: max_number_of_messages(),
        visibility_timeout: visibility_timeout()
      )
      |> ExAws.request!()
      |> parse_messages

    {:reply, messages, queue}
  end

  def handle_cast({:delete_message, queue, receipt_handle}, state) do
    ExAws.SQS.delete_message(queue, receipt_handle)
    |> ExAws.request!()

    {:noreply, state}
  end
end
