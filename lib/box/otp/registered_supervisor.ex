defmodule Box.Otp.RegisteredSupervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: Keyword.get(args, :name))
  end

  @default_strategy :one_for_rest
  def init(_args) do
    children = Keyword.get(args, :children, [])
    strategy = Keyword.get(args, :strategy, @default_strategy)

    Supervisor.init([],
      strategy: strategy
    )
  end
end
