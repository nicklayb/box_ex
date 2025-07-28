defmodule Box.PoolProcessor.QueueBehaviour do
  @type watcher :: pid()

  @type state :: any()

  @callback init(Keyword.t()) :: {:ok, state()} | {:load, state()}
  @callback load(state(), Keyword.t()) :: state()
  @callback enqueue(state(), Box.PoolProcessor.execute_function(), [watcher()]) :: state()
  @callback dequeue(state()) ::
              :empty | {Box.PoolProcessor.execute_function(), [watcher()], state()}

  def init({module, options}) do
    module.init(options)
  end

  def load({module, options}, state) do
    module.load(state, options)
  end

  def enqueue({module, _}, state, mfa, watchers) do
    module.enqueue(state, mfa, watchers)
  end

  def dequeue({module, _}, state) do
    module.dequeue(state)
  end
end
