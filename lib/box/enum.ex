defmodule Box.Enum do
  @moduledoc """
  Extra functions to work with Enums.
  """

  @doc """
  Replaces a value in an enumerable from a given function.

  ## Exmaples

      iex> Box.Enum.replace([1, 2, 3, 4], &(&1 == 3), 10)
      [1, 2, 10, 4]
  """
  @spec replace(Enumerable.t(), (any() -> boolean()), any()) :: Enumerable.t()
  def replace(enumerable, finder, new_value) do
    Enum.map(enumerable, fn current ->
      if finder.(current), do: new_value, else: current
    end)
  end

  @doc """
  Creates a map from an enumerable keyed by a given function

  ## Examples

    iex> Box.Enum.key_by([1, 2, 3], &(&1 *10))
    %{10 => 1, 20 => 2, 30 => 3}
  """
  @spec key_by(Enumerable.t(), (any() -> any())) :: map()
  def key_by(enumerable, key_getter) do
    Enum.reduce(enumerable, %{}, fn item, acc ->
      Map.put(acc, key_getter.(item), item)
    end)
  end

  @doc """
  Maps an enumerable to get a given map's field

  ## Examples

    iex> Box.Enum.field([%{value: 1}, %{value: 2}], :value)
    [1, 2]
  """
  @spec field(Enumerable.t(map()), atom() | String.t()) :: Enumerable.t()
  def field(enumerable, field) do
    Enum.map(enumerable, &Map.get(&1, field))
  end
end
