if Code.ensure_loaded?(Phoenix.PubSub) do
  defmodule Box.PubSub.Dispatcher do
    alias Box.PubSub.Message

    @doc "Dispatches a wrapped message to the receipients"
    @spec dispatch([pid()], pid(), {String.t(), message()}) :: :ok
    def dispatch(entries, from, message) do
      {topic, message, metadata} =
        case message do
          {topic, message} -> {topic, message, %{}}
          {topic, message, metadata} -> {topic, message, metadata}
        end

      message = Message.new(message, topic, from: from, metadata: metadata)

      Phoenix.PubSub.dispatch(entries, from, message)
    end
  end
end

