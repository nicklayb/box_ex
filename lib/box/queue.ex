defmodule Box.Queue do
  @moduledoc """
  Queue data structure
  """

  @type t :: :queue.queue()

  @spec new() :: t()
  def new, do: :queue.new()

  @spec insert(t(), any()) :: t()
  def insert(queue, item) do
    :queue.in(item, queue)
  end

  @spec out(t()) :: {:empty, t()} | {{:value, any()}, t()}
  def out(queue) do
    :queue.out(queue)
  end
end
