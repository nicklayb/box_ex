defmodule Box.Cache.Server do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: Keyword.fetch!(args, :name))
  end

  @impl GenServer
  def init(args) do
    {name, options} = Keyword.pop(args, :name)
    ref = :ets.new(name, [:protected, :named_table, :set | options])

    {:ok, %{name: name, ref: ref, observers: %{}, monitors: %{}}}
  end

  @impl GenServer

  def handle_info({:DOWN, _monitor_ref, _process, pid, _reason}, state) do
    keys = observed_keys(state, pid)
    state = deobserve(state, keys, pid)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:delete, key}, %{ref: ref} = state) do
    :ets.delete(ref, key)
    notify_observers(state, [{:deleted, key}])
    {:noreply, state}
  end

  def handle_cast({:insert, record_or_records, options}, %{ref: ref} = state) do
    expiration =
      case Keyword.get(options, :ttl, :infinity) do
        :infinity -> :never
        millisecond -> System.monotonic_time(:millisecond) + millisecond
      end

    records =
      record_or_records
      |> List.wrap()
      |> Enum.map(fn {key, value} ->
        {key, value, expiration: expiration}
      end)

    :ets.insert(ref, records)
    entries = Enum.map(records, fn {key, value, _} -> {:inserted, key, value} end)
    notify_observers(state, entries)
    {:noreply, state}
  end

  def handle_cast({:observe, key_or_keys, caller}, state) do
    state = observe(state, key_or_keys, caller)

    {:noreply, state}
  end

  def handle_cast({:deobserve, key_or_keys, caller}, state) do
    state = deobserve(state, key_or_keys, caller)

    {:noreply, state}
  end

  defp notify_observers(state, entries) do
    Enum.each(entries, fn
      {:deleted, key} ->
        notify_observers(state, key, :deleted)

      {:inserted, key, value} ->
        notify_observers(state, key, {:inserted, value})
    end)
  end

  defp notify_observers(state, key, message) do
    state.observers
    |> Map.get(key, [])
    |> Enum.each(fn caller -> send(caller, {state.name, key, message}) end)
  end

  defp observed_keys(state, caller) do
    Enum.reduce(state.observers, [], fn {key, callers}, acc ->
      if caller in callers do
        [key | acc]
      else
        acc
      end
    end)
  end

  defp deobserve(state, key_or_keys, caller) do
    key_or_keys
    |> List.wrap()
    |> Enum.reduce(state, &remove_observer(&2, &1, caller))
    |> demonitor(caller)
  end

  defp observe(state, key_or_keys, caller) do
    key_or_keys
    |> List.wrap()
    |> Enum.reduce(state, &add_observer(&2, &1, caller))
    |> monitor(caller)
  end

  defp add_observer(state, key, caller) do
    observers = Map.update(state.observers, key, [caller], &Enum.uniq([caller | &1]))

    %{state | observers: observers}
  end

  defp remove_observer(state, key, caller) do
    observers =
      state.observers
      |> Map.update(key, [], &(&1 -- [caller]))
      |> clear_if_empty(key)

    %{state | observers: observers}
  end

  defp clear_if_empty(observers, key) do
    if Map.get(observers, key) == [] do
      Map.delete(observers, key)
    else
      observers
    end
  end

  defp monitor(state, caller) do
    case Map.get(state.monitors, caller) do
      ref when is_reference(ref) ->
        state

      nil ->
        monitor_ref = Process.monitor(caller)
        Map.update!(state, :monitors, &Map.put(&1, caller, monitor_ref))
    end
  end

  defp demonitor(state, caller) do
    case Map.get(state.monitors, caller) do
      ref when is_reference(ref) ->
        Process.demonitor(ref)
        Map.update!(state, :monitors, &Map.delete(&1, caller))

      nil ->
        state
    end
  end
end
