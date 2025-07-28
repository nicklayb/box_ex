defmodule Box.PoolProcessor.Manager do
  use GenServer

  require Logger

  alias Box.PoolProcessor.QueueBehaviour
  alias Box.PoolProcessor.Manager.State

  @type option ::
          {:size, non_neg_integer()}
          | {:supervisor_pid, pid()}
          | {:queue, State.queue_spec() | module()}

  @doc "Starts a state"
  @spec start_link([option()]) :: GenServer.on_start()
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(args) do
    case State.init(args) do
      {:ok, state} -> {:ok, state}
      {:load_queue, state} -> {:ok, state, {:continue, :backfill}}
    end
  end

  @impl GenServer
  def handle_call({:sync, function}, from, %State{} = state) do
    state = State.enqueue(state, function, [from])

    {:noreply, state, {:continue, :backfill}}
  end

  @impl GenServer
  def handle_cast({:async, function}, %State{} = state) do
    state = State.enqueue(state, function)

    {:noreply, state, {:continue, :backfill}}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, pid, _}, %State{} = state) do
    Logger.debug("[#{inspect(__MODULE__)}] [#{inspect(pid)}] down")

    notify_watchers(state, ref)

    state = State.finish_process(state, ref)

    {:noreply, state, {:continue, :backfill}}
  end

  def handle_info(:load_queue, %State{} = state) do
    state =
      State.map_queue_state(state, fn queue_spec, state ->
        QueueBehaviour.load(queue_spec, state)
      end)

    {:noreply, state, {:continue, :backfill}}
  end

  def handle_info(:dequeue, %State{} = state) do
    state = State.dequeue(state)

    {:noreply, state}
  end

  @impl GenServer
  def handle_continue(:backfill, %State{} = state) do
    case State.backfill(state) do
      {:continue, state} ->
        {:noreply, state, {:continue, :backfill}}

      {:done, state} ->
        {:noreply, state}
    end
  end

  defp notify_watchers(%State{watchers: watchers}, ref) when is_map_key(watchers, ref) do
    watchers
    |> Map.fetch!(ref)
    |> Enum.each(&GenServer.reply(&1, :ok))
  end

  defp notify_watchers(_, _), do: :ok
end
