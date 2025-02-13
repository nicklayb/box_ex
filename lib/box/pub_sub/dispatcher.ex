if Code.ensure_loaded?(Phoenix.PubSub) do
  defmodule Box.PubSub.Dispatcher do
    alias Box.PubSub.Message

    @doc "Dispatches a wrapped message to the receipients"
    @spec dispatch([pid()], pid(), {String.t(), Message.input_message(), any()}) :: :ok
    def dispatch(entries, from, {topic, message, metadata}) do
      message = Message.new(message, topic, from: from, metadata: metadata)

      Phoenix.PubSub.dispatch(entries, from, message)
    end
  end
end
