defmodule Box.PoolProcessor.Queue do
  @behaviour Box.PoolProcessor.QueueBehaviour
  alias Box.PoolProcessor.QueueBehaviour

  @impl QueueBehaviour
  def init(_) do
    {:ok, Box.Queue.new()}
  end

  @impl QueueBehaviour
  def enqueue(queue, mfa, watchers) do
    Box.Queue.insert(queue, {mfa, watchers})
  end

  @impl QueueBehaviour
  def dequeue(queue) do
    case Box.Queue.out(queue) do
      {:empty, _} ->
        :empty

      {{:value, {function, watchers}}, new_queue} ->
        {function, watchers, new_queue}
    end
  end

  @impl QueueBehaviour
  def load(queue, _), do: queue
end

defmodule Box.PoolProcessor.List do
  @behaviour Box.PoolProcessor.QueueBehaviour
  alias Box.PoolProcessor.QueueBehaviour

  @impl QueueBehaviour
  def init(_) do
    {:ok, []}
  end

  @impl QueueBehaviour
  def enqueue(list, function, watchers) do
    [{function, watchers} | list]
  end

  @impl QueueBehaviour
  def dequeue([{function, watchers} | rest]) do
    {function, watchers, rest}
  end

  def dequeue([]), do: :empty

  @impl QueueBehaviour
  def load(list, _), do: list
end

defmodule Run do
  def start(timer, _args) do
    Process.sleep(timer)
  end

  def spec(timer, args) do
    {Run, :start, [timer, args]}
  end
end
