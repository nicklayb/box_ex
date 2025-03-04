defmodule Box.Cache.Server do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: Keyword.fetch!(args, :name))
  end

  @impl GenServer
  def init(args) do
    {name, options} = Keyword.pop(args, :name)
    ref = :ets.new(name, [:protected, :named_table, :set | options])

    {:ok, %{name: name, ref: ref}}
  end

  @impl GenServer
  def handle_cast({:delete, key}, %{ref: ref} = state) do
    :ets.delete(ref, key)
    {:noreply, state}
  end

  @impl GenServer
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
    {:noreply, state}
  end
end
