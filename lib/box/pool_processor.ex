defmodule Box.PoolProcessor do
  @moduledoc """
  Starts a pool processor that runs jobs concurrently

  ## Examples

      iex> Box.PoolProcessor.start_link(name: MyPool, size: 10)
      {:ok, pid}
    
      iex> Box.PoolProcessor.async(MyPool, fn -> IO.inspect("Hello") end)
      :ok
  """
  use Supervisor

  alias Box.PoolProcessor
  alias Box.PoolProcessor.Manager

  @type pool_supervisor :: atom() | pid()

  @type option :: {:size, non_neg_integer()}

  @type execute_function :: function() | mfa()

  @doc """
  Starts a pool supervisor
  """
  @spec start_link([option()]) :: Supervisor.on_start_child()
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: Keyword.get(args, :name))
  end

  @impl Supervisor
  def init(args) do
    children = [
      {Manager, Keyword.merge(args, supervisor_pid: self())},
      DynamicSupervisor
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  @doc """
  Enqueues a function call in the pool asynchronously
  """
  @spec async(pool_supervisor(), execute_function()) :: :ok
  def async(pool, function) do
    pool
    |> manager()
    |> GenServer.cast({:async, function})
  end

  @default_timeout :timer.seconds(5)
  @doc """
  Enqueues a function call and awaits for it to be completed.
  """
  @spec sync(pool_supervisor(), execute_function(), non_neg_integer()) :: :ok
  def sync(pool, function, timeout \\ @default_timeout) do
    pool
    |> manager()
    |> GenServer.call({:sync, function}, timeout)
  end

  @doc """
  Starts a child in the pool supervisor
  """
  @spec start_child(pool_supervisor(), execute_function()) :: {:ok, pid()}
  def start_child(pool, function) do
    pool
    |> supervisor()
    |> DynamicSupervisor.start_child(process_spec(function))
  end

  defp process_spec(function) do
    %{
      id: nil,
      start: {PoolProcessor, :spawn_process, [function]},
      restart: :transient
    }
  end

  def spawn_process(function) do
    pid =
      case function do
        {module, function, arguments} ->
          spawn_link(module, function, arguments)

        function when is_function(function, 0) ->
          spawn_link(function)
      end

    {:ok, pid}
  end

  defp manager(pool) do
    pool
    |> Supervisor.which_children()
    |> Enum.find_value(fn
      {Manager, pid, :worker, _} -> pid
      _ -> nil
    end)
  end

  defp supervisor(pool) do
    pool
    |> Supervisor.which_children()
    |> Enum.find_value(fn
      {DynamicSupervisor, pid, :supervisor, _} -> pid
      _ -> nil
    end)
  end
end
