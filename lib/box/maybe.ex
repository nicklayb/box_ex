defmodule Box.Maybe do
  @type t :: nil | any()

  @spec map(t(), (any() -> any())) :: t()
  def map(nil, _), do: nil
  def map(value, function), do: function.(value)

  @spec with_default(t(), (-> any()) | any()) :: any()
  def with_default(nil, function) when is_function(function, 0), do: function.()
  def with_default(nil, default), do: default
  def with_default(value, _), do: value
end
