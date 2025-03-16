defmodule Box.PubSubTest do
  use Box.BaseCase

  defmodule TestPubSub do
    use Box.PubSub

    def after_resubscribe(topic_or_topics, options) do
      send(self(), {:resubscribe, topic_or_topics, options})
      :ok
    end

    def after_unsubscribe(topic_or_topics, options) do
      send(self(), {:unsubscribe, topic_or_topics, options})
      :ok
    end

    def after_subscribe(topic_or_topics, options) do
      send(self(), {:subscribe, topic_or_topics, options})
      :ok
    end

    def after_broadcast(topic_or_topics, message_or_messages, options) do
      send(self(), {:broadcast, topic_or_topics, message_or_messages, options})
      :ok
    end

    def put_default_options(options) do
      Keyword.put(options, :topic_generator, &topic/1)
    end

    defp topic(atom) when is_atom(atom), do: "atom:#{atom}"
    defp topic(other), do: other
  end

  defmodule TestPubSubNoCallback do
    use Box.PubSub

    def put_default_options(options) do
      Keyword.put(options, :topic_generator, &topic/1)
    end

    defp topic(atom) when is_atom(atom), do: "atom:#{atom}"
    defp topic(other), do: other
  end

  setup context do
    server = Map.get(context, :server, TestPubSubNoCallback)
    pub_sub_pid = start_supervised!(server)

    [pid: pub_sub_pid, server: server]
  end

  describe "subscribe/2" do
    test "subscribe to topic", %{server: server} do
      server.subscribe("topic")
      refute_receive({:subscribe, _, _})
      server.broadcast("topic", :hello)
      assert_receive(%Box.PubSub.Message{message: :hello})
    end

    test "subscribe to topic and invokes topic generator", %{server: server} do
      server.subscribe(:topic)
      refute_receive({:subscribe, _, _})
      server.broadcast("atom:topic", :hello)
      assert_receive(%Box.PubSub.Message{message: :hello})
    end

    @tag server: TestPubSub
    test "subscribe to topic and invoke after_subscribe", %{server: server} do
      server.subscribe("topic")
      assert_receive({:subscribe, "topic", _})
    end

    test "subscribe to multiple topics", %{server: server} do
      server.subscribe(["1", "2"])
      server.broadcast("1", :got_1)
      assert_receive(%Box.PubSub.Message{topic: "1", message: :got_1})
      server.broadcast("2", :got_2)
      assert_receive(%Box.PubSub.Message{topic: "2", message: :got_2})

      server.broadcast(["1", "2"], :to_all)
      assert_receive(%Box.PubSub.Message{topic: "1", message: :to_all})
      assert_receive(%Box.PubSub.Message{topic: "2", message: :to_all})
    end
  end

  describe "unsubscribe/2" do
    test "unsubscribe to topic", %{server: server} do
      server.subscribe("topic")
      server.broadcast("topic", :hello)
      assert_receive(%Box.PubSub.Message{message: :hello})
      server.unsubscribe("topic")
      refute_receive({:unsubscribe, _, _})
      server.broadcast("topic", :hello)
      refute_receive(%Box.PubSub.Message{message: :hello})
    end

    test "unsubscribe to topic using topic generator", %{server: server} do
      server.subscribe("atom:topic")
      server.broadcast("atom:topic", :hello)
      assert_receive(%Box.PubSub.Message{message: :hello})
      server.unsubscribe(:topic)
      refute_receive({:unsubscribe, _, _})
      server.broadcast("atom:topic", :hello)
      refute_receive(%Box.PubSub.Message{message: :hello})
    end

    @tag server: TestPubSub
    test "unsubscribe to topic and invoke after_unsubscribe", %{server: server} do
      server.subscribe("topic")
      server.broadcast("topic", :hello)
      assert_receive(%Box.PubSub.Message{message: :hello})
      server.unsubscribe("topic")
      assert_receive({:unsubscribe, "topic", _})
      refute_receive(%Box.PubSub.Message{message: :hello})
    end

    test "unsubscribe to multiple topics", %{server: server} do
      server.subscribe(["1", "2"])
      server.broadcast(["1", "2"], :hello)
      assert_receive(%Box.PubSub.Message{topic: "1", message: :hello})
      assert_receive(%Box.PubSub.Message{topic: "2", message: :hello})
      server.unsubscribe(["1", "2"])
      server.broadcast(["1", "2"], :hello)
      refute_receive(%Box.PubSub.Message{topic: "1", message: :hello})
      refute_receive(%Box.PubSub.Message{topic: "2", message: :hello})
    end
  end

  describe "resubscribe" do
    test "unsubscribes all subscription and resubscribes once", %{server: server} do
      server.subscribe("topic")
      server.subscribe("topic")
      server.broadcast("topic", :hello)
      assert_receive(%Box.PubSub.Message{topic: "topic", message: :hello})
      assert_receive(%Box.PubSub.Message{topic: "topic", message: :hello})
      server.resubscribe("topic")
      refute_receive({:resubscribe, "topic", _})
      server.broadcast("topic", :hello)
      assert_receive(%Box.PubSub.Message{topic: "topic", message: :hello})
      refute_receive(%Box.PubSub.Message{topic: "topic", message: :hello})
    end

    test "unsubscribes all subscription and resubscribes once with topic generator", %{
      server: server
    } do
      server.subscribe("atom:topic")
      server.subscribe("atom:topic")
      server.broadcast("atom:topic", :hello)
      assert_receive(%Box.PubSub.Message{topic: "atom:topic", message: :hello})
      assert_receive(%Box.PubSub.Message{topic: "atom:topic", message: :hello})
      server.resubscribe(:topic)
      refute_receive({:resubscribe, "atom:topic", _})
      server.broadcast("atom:topic", :hello)
      assert_receive(%Box.PubSub.Message{topic: "atom:topic", message: :hello})
      refute_receive(%Box.PubSub.Message{topic: "atom:topic", message: :hello})
    end

    @tag server: TestPubSub
    test "unsubscribes all subscription and resubscribes once and invoke after_resubscribe", %{
      server: server
    } do
      server.subscribe("topic")
      server.subscribe("topic")
      server.broadcast("topic", :hello)
      assert_receive(%Box.PubSub.Message{topic: "topic", message: :hello})
      assert_receive(%Box.PubSub.Message{topic: "topic", message: :hello})
      server.resubscribe("topic")
      assert_receive({:resubscribe, "topic", _})
      server.broadcast("topic", :hello)
      assert_receive(%Box.PubSub.Message{topic: "topic", message: :hello})
      refute_receive(%Box.PubSub.Message{topic: "topic", message: :hello})
    end

    @tag server: TestPubSub
    test "unsubscribes all subscription and resubscribes to multiple topics once and invoke after_resubscribe",
         %{
           server: server
         } do
      server.subscribe(["topic", "topic", "other"])
      server.broadcast("topic", :hello)
      assert_receive(%Box.PubSub.Message{topic: "topic", message: :hello})
      assert_receive(%Box.PubSub.Message{topic: "topic", message: :hello})
      server.broadcast("other", :hello)
      assert_receive(%Box.PubSub.Message{topic: "other", message: :hello})
      refute_receive(%Box.PubSub.Message{topic: "topic", message: :hello})

      server.resubscribe(["topic", "other"])
      server.broadcast("topic", :hello)
      assert_receive(%Box.PubSub.Message{topic: "topic", message: :hello})
      refute_receive(%Box.PubSub.Message{topic: "topic", message: :hello})
      server.broadcast("other", :hello)
      assert_receive(%Box.PubSub.Message{topic: "other", message: :hello})
      refute_receive(%Box.PubSub.Message{topic: "other", message: :hello})
    end
  end

  describe "broadcast/3" do
    test "broadcasts wrapped message", %{server: server} do
      server.subscribe("topic")
      server.broadcast("topic", :hello)
      refute_receive({:broadcast, "topic", :hello, _})
      assert_receive(%Box.PubSub.Message{topic: "topic", message: :hello})
      server.broadcast("topic", :hello, dispatcher: nil)
      assert_receive(:hello)
      refute_receive(%Box.PubSub.Message{topic: "topic", message: :hello})
      server.broadcast("topic", :hello, dispatcher: nil, raw: true)
      assert_receive({"topic", :hello, nil})
      server.broadcast("topic", :hello, dispatcher: nil, raw: true, metadata: :metadata)
      assert_receive({"topic", :hello, :metadata})
    end

    test "broadcasts wrapped message using topic generator", %{server: server} do
      server.subscribe("atom:topic")
      server.broadcast(:topic, :hello)
      refute_receive({:broadcast, "atom:topic", :hello, _})
      assert_receive(%Box.PubSub.Message{topic: "atom:topic", message: :hello})
      server.broadcast(:topic, :hello, dispatcher: nil)
      assert_receive(:hello)
      refute_receive(%Box.PubSub.Message{topic: "atom:topic", message: :hello})
      server.broadcast(:topic, :hello, dispatcher: nil, raw: true)
      assert_receive({"atom:topic", :hello, nil})
      server.broadcast(:topic, :hello, dispatcher: nil, raw: true, metadata: :metadata)
      assert_receive({"atom:topic", :hello, :metadata})
    end

    @tag server: TestPubSub
    test "broadcasts wrapped message and invoke after_broadcast", %{server: server} do
      server.subscribe("topic")
      server.broadcast("topic", :hello)
      assert_receive({:broadcast, "topic", :hello, _})
      assert_receive(%Box.PubSub.Message{topic: "topic", message: :hello})
    end

    test "broadcasts multiple messages to multiple topics", %{server: server} do
      server.subscribe(["1", "2"])
      server.broadcast(["1", "2"], [:first, :second])
      assert_receive(%Box.PubSub.Message{topic: "1", message: :first})
      assert_receive(%Box.PubSub.Message{topic: "1", message: :second})
      assert_receive(%Box.PubSub.Message{topic: "2", message: :first})
      assert_receive(%Box.PubSub.Message{topic: "2", message: :second})
    end

    test "broadcasts message with parameters", %{server: server} do
      server.subscribe("topic")
      server.broadcast("topic", {:message, :body})

      assert_receive(%Box.PubSub.Message{
        topic: "topic",
        message: :message,
        params: :body,
        metadata: nil
      })
    end

    test "broadcasts message with parameters and metadata", %{server: server} do
      server.subscribe("topic")
      server.broadcast("topic", {:message, :body}, metadata: %{hello: :value})

      assert_receive(%Box.PubSub.Message{
        topic: "topic",
        message: :message,
        params: :body,
        metadata: %{hello: :value}
      })
    end
  end
end
