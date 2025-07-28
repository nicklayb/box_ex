defmodule Box.PoolProcessor.Manager.State do
  alias Box.PoolProcessor
  alias Box.PoolProcessor.QueueBehaviour
  alias Box.PoolProcessor.Manager.State

  defstruct [:supervisor_pid, :size, :queue, processes: [], watchers: %{}]

  require Logger

  @type queue_state :: any()
  @type queue_spec :: {module(), Keyword.t()}
  @type queue :: {queue_spec(), queue_state()}

  @type t :: %State{
          supervisor_pid: pid(),
          size: non_neg_integer(),
          queue: queue(),
          processes: [reference()],
          watchers: %{reference() => [pid()]}
        }

  @type init_option ::
          {:supervisor_pid, pid()}
          | {:size, non_neg_integer()}
          | {:queue, queue_spec() | module()}

  @default_size 5
  @spec init([init_option()]) :: {:load_queue, t()} | {:ok, t()}
  def init(args) do
    {queue, load?} = init_queue(args)

    state = %State{
      supervisor_pid: Keyword.fetch!(args, :supervisor_pid),
      size: Keyword.get(args, :size, @default_size),
      queue: queue
    }

    if load? do
      {:load_queue, state}
    else
      {:ok, state}
    end
  end

  defp init_queue(args) do
    queue_spec =
      case Keyword.get(args, :queue, Box.PoolProcessor.Queue) do
        {module, options} -> {module, options}
        module -> {module, []}
      end

    {state, load?} =
      case QueueBehaviour.init(queue_spec) do
        {:ok, state} ->
          {state, false}

        {:load, state} ->
          {state, true}
      end

    {{queue_spec, state}, load?}
  end

  defp process(%State{supervisor_pid: supervisor_pid} = state, function, watchers) do
    {:ok, pid} = PoolProcessor.start_child(supervisor_pid, function)

    ref = Process.monitor(pid)

    Logger.debug(
      "[#{inspect(__MODULE__)}] [#{inspect(pid)}] [#{function_to_string(function)}] starting"
    )

    state
    |> map_processes(&[ref | &1])
    |> map_watchers(&Map.put(&1, ref, watchers))
  end

  @spec finish_process(t(), reference()) :: t()
  def finish_process(%State{} = state, ref) do
    state
    |> map_processes(&(&1 -- [ref]))
    |> map_watchers(&Map.delete(&1, ref))
  end

  @spec enqueue(t(), function(), [GenServer.from()]) :: t()
  def enqueue(%State{} = state, function, watchers \\ []) do
    Logger.debug("[#{inspect(__MODULE__)}] [#{function_to_string(function)}] enequeued")
    map_queue_state(state, &QueueBehaviour.enqueue(&1, &2, function, watchers))
  end

  @spec dequeue(t()) :: t()
  def dequeue(%State{queue: {queue_spec, queue_state}} = state) do
    case {QueueBehaviour.dequeue(queue_spec, queue_state), has_room?(state)} do
      {:empty, _} ->
        state

      {{next_function, watchers, queue}, true} ->
        state
        |> process(next_function, watchers)
        |> map_queue_state(fn _, _ -> queue end)

      {_, false} ->
        state
    end
  end

  @type queue_state_mapper :: (queue_spec(), queue_state() -> queue_state())
  @spec map_queue_state(t(), queue_state_mapper()) :: t()
  def map_queue_state(%State{queue: {queue_spec, queue_state}} = state, function) do
    new_state = function.(queue_spec, queue_state)
    %State{state | queue: {queue_spec, new_state}}
  end

  defp map_processes(%State{processes: processes} = state, function) do
    %State{state | processes: function.(processes)}
  end

  defp map_watchers(%State{watchers: watchers} = state, function) do
    %State{state | watchers: function.(watchers)}
  end

  @spec backfill(t()) :: {:continue, t()} | {:done, t()}
  def backfill(%State{} = state) do
    state = dequeue(state)

    if has_room?(state) and not queue_empty?(state) do
      {:continue, state}
    else
      {:done, state}
    end
  end

  defp has_room?(%State{size: size, processes: processes}) do
    length(processes) < size
  end

  defp queue_empty?(%State{queue: {queue_spec, queue_state}}) do
    case QueueBehaviour.dequeue(queue_spec, queue_state) do
      :empty -> true
      _ -> false
    end
  end

  defp function_to_string({module, function, arguments}) do
    function_to_string(module, function, arguments)
  end

  defp function_to_string(function) when is_function(function, 0) do
    inspect(function)
  end

  defp function_to_string(module, function, arguments) do
    "#{inspect(module)}.#{to_string(function)}/#{length(arguments)}"
  end
end
