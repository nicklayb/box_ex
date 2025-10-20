defmodule Box.Zipper do
  @moduledoc """
  Data structure that zips over a single data
  """
  alias Box.Zipper

  defstruct previous: [], next: [], current: nil

  @type t :: %Zipper{previous: list(), next: list(), current: any()}

  defguardp is_cont_or_reset(cont_or_reset) when cont_or_reset in ~w(cont reset)a

  @spec new(nonempty_list()) :: t()
  def new([current | next]) do
    %Zipper{next: next, current: current}
  end

  def new([]), do: raise(ArgumentError, message: "List must not be empty")

  @type move_result :: {:cont, t()} | {:reset, t()}

  @spec new(t() | move_result()) :: move_result()
  def next(%Zipper{previous: previous, current: current, next: []}) do
    [current | next] = Enum.reverse([current | previous])
    {:reset, %Zipper{next: next, previous: [], current: current}}
  end

  def next(%Zipper{previous: previous, current: current, next: [new_current | next]}) do
    {:cont, %Zipper{previous: [current | previous], current: new_current, next: next}}
  end

  def next({cont_or_reset, %Zipper{} = zipper}) when is_cont_or_reset(cont_or_reset) do
    next(zipper)
  end

  @spec previous(t() | move_result()) :: move_result()
  def previous(%Zipper{previous: [], current: current, next: next}) do
    [current | previous] = Enum.reverse([current | next])

    {:cont, %Zipper{previous: previous, current: current, next: []}}
  end

  def previous(%Zipper{previous: [new_current | previous], current: current, next: next}) do
    case %Zipper{previous: previous, current: new_current, next: [current | next]} do
      %Zipper{previous: []} = zipper -> {:reset, zipper}
      %Zipper{} = zipper -> {:cont, zipper}
    end
  end

  def previous({cont_or_reset, %Zipper{} = zipper}) when is_cont_or_reset(cont_or_reset) do
    previous(zipper)
  end

  @spec current(t()) :: any()
  def current(%Zipper{current: current}) do
    current
  end

  @spec reset(t()) :: t()
  def reset(%Zipper{previous: []} = zipper) do
    zipper
  end

  def reset(zipper) do
    case next(zipper) do
      {:cont, new_zipper} ->
        reset(new_zipper)

      {:reset, new_zipper} ->
        new_zipper
    end
  end
end
