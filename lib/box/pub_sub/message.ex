if Code.ensure_loaded?(Phoenix.PubSub) do
  defmodule Box.PubSub.Message do
    @moduledoc """
    Pub sub message wrapping structure
    """
    defstruct [:message, :params, :from, :topic, :metadata]

    alias Box.PubSub.Message

    @type message :: atom()
    @type input_message :: atom() | {message(), any()}
    @type t :: %Message{
            message: message(),
            params: any(),
            from: pid(),
            topic: String.t(),
            metadata: map()
          }

    @doc "Builds a pub sub message"
    @spec new(message(), String.t(), Keyword.t()) :: t()
    def new(message, topic, options \\ []) do
      from = Keyword.get_lazy(options, :from, fn -> self() end)
      metadata = Keyword.get(options, :metadata, %{})

      {message, params} =
        case message do
          {message, params} -> {message, params}
          message when is_atom(message) -> {message, nil}
        end

      %Message{message: message, params: params, topic: topic, from: from}
    end
  end
end

