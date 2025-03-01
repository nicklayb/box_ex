if Code.ensure_loaded?(Phoenix.PubSub) do
  defmodule Box.PubSub do
    defmacro __using__(options) do
      quote do
        @server Keyword.get(unquote(options), :server, __MODULE__)
        @dispatcher Keyword.get(unquote(options), :dispatcher, Box.PubSub.Dispatcher)

        def child_spec(args) do
          %{
            id: @server,
            start: {Phoenix.PubSub.Supervisor, :start_link, [Keyword.put(args, :name, @server)]}
          }
        end

        def broadcast(topic_or_topics, message_or_messages, options \\ []) do
          @server
          |> Box.PubSub.broadcast(
            topic_or_topics,
            message_or_messages,
            with_default_broadcast_options(options)
          )
          |> tap(fn _ -> after_broadcast(topic_or_topics, message_or_messages, options) end)
        end

        def subscribe(topic_or_topics, options \\ []) do
          @server
          |> Box.PubSub.subscribe(topic_or_topics, options)
          |> tap(fn _ -> after_subscribe(topic_or_topics, options) end)
        end

        def resubscribe(topic_or_topics, options \\ []) do
          @server
          |> Box.PubSub.resubscribe(topic_or_topics, options)
          |> tap(fn _ -> after_resubscribe(topic_or_topics, options) end)
        end

        def unsubscribe(topic_or_topics, options \\ []) do
          @server
          |> Box.PubSub.unsubscribe(topic_or_topics, options)
          |> tap(fn _ -> after_unsubscribe(topic_or_topics, options) end)
        end

        def after_resubscribe(_topic_or_topics, _options) do
          :ok
        end

        def after_unsubscribe(_topic_or_topics, _options) do
          :ok
        end

        def after_subscribe(_topic_or_topics, _options) do
          :ok
        end

        def after_broadcast(_topic_or_topics, _message_or_messages, _options) do
          :ok
        end

        defp with_default_broadcast_options(options) do
          Keyword.put_new(options, :dispatcher, @dispatcher)
        end

        defoverridable(
          after_broadcast: 3,
          after_resubscribe: 2,
          after_unsubscribe: 2,
          after_subscribe: 2
        )
      end
    end

    def resubscribe(server, topic_or_topics, options \\ []) do
      unsubscribe(server, topic_or_topics, options)
      subscribe(server, topic_or_topics, options)
    end

    def unsubscribe(server, topic_or_topics, _options \\ []) do
      topic_or_topics
      |> List.wrap()
      |> Enum.each(&Phoenix.PubSub.unsubscribe(server, &1))
    end

    def broadcast(server, topic_or_topics, message_or_messages, options \\ []) do
      dispatcher = Keyword.get(options, :dispatcher, Box.PubSub.Dispatcher) || Phoenix.PubSub

      topic_or_topics
      |> List.wrap()
      |> Enum.each(fn topic ->
        message_or_messages
        |> List.wrap()
        |> Enum.each(fn message ->
          broadcast_message(server, topic, message, dispatcher, options)
        end)
      end)
    end

    defp broadcast_message(server, topic, message, dispatcher, options) do
      message =
        if dispatcher == Box.PubSub.Dispatcher or
             Keyword.get(options, :raw, false) do
          metadata = Keyword.get(options, :metadata, nil)
          {topic, message, metadata}
        else
          message
        end

      Phoenix.PubSub.broadcast(server, topic, message, dispatcher)
    end

    def subscribe(server, topic_or_topics, _options \\ []) do
      topic_or_topics
      |> List.wrap()
      |> Enum.each(&Phoenix.PubSub.subscribe(server, &1))
    end
  end
end
