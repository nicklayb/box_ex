defmodule Box.PoolProcessor.Queue do
  alias Box.PoolProcessor.QueueBehaviour
  @behaviour QueueBehaviour

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
  alias Box.PoolProcessor.QueueBehaviour
  @behaviour QueueBehaviour

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
  def start(timer, args) do
    IO.inspect("#{args} Started")
    Process.sleep(timer)
    IO.inspect("#{args} Done")
  end

  def spec(timer, args) do
    {Run, :start, [timer, args]}
  end
end
