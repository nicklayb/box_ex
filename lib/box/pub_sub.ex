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
          options =
            options
            |> put_default_options()
            |> with_default_broadcast_options()

          @server
          |> Box.PubSub.broadcast(
            topic_or_topics,
            message_or_messages,
            options
          )
          |> tap(fn _ -> after_broadcast(topic_or_topics, message_or_messages, options) end)
        end

        def subscribe(topic_or_topics, options \\ []) do
          options = put_default_options(options)

          @server
          |> Box.PubSub.subscribe(topic_or_topics, options)
          |> tap(fn _ -> after_subscribe(topic_or_topics, options) end)
        end

        def resubscribe(topic_or_topics, options \\ []) do
          options = put_default_options(options)

          @server
          |> Box.PubSub.resubscribe(topic_or_topics, options)
          |> tap(fn _ -> after_resubscribe(topic_or_topics, options) end)
        end

        def unsubscribe(topic_or_topics, options \\ []) do
          options = put_default_options(options)

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

        def put_default_options(options) do
          options
        end

        defoverridable(
          put_default_options: 1,
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

    def unsubscribe(server, topic_or_topics, options \\ []) do
      topic_or_topics
      |> List.wrap()
      |> Enum.each(fn topic ->
        Phoenix.PubSub.unsubscribe(server, generate_topic(topic, options))
      end)
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
      topic = generate_topic(topic, options)

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

    def subscribe(server, topic_or_topics, options \\ []) do
      topic_or_topics
      |> List.wrap()
      |> Enum.each(fn topic ->
        Phoenix.PubSub.subscribe(server, generate_topic(topic, options))
      end)
    end

    defp generate_topic(topic, options) do
      case Keyword.get(options, :topic_generator) do
        function when is_function(function, 1) -> function.(topic)
        _ -> topic
      end
    end
  end
end
