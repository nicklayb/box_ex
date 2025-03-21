defmodule Box.Map do
  @moduledoc """
  Extra functions to work with map. 

  Specifically, this include function to work with maps independent
  of the key type. These functions should be used everywhere we
  manipulate changeset params to ensure they both work with string
  and atom maps and support UI inputs as well as console input.
  """

  @doc """
  Gets first entry that matches in the map
  """
  @spec get_first(map(), [atom()]) :: {atom(), any()} | nil
  def get_first(map, keys) do
    Enum.find_value(keys, fn key ->
      case get(map, key) do
        nil -> false
        value -> {key, value}
      end
    end)
  end

  @doc """
  Puts a value in a map. The provided needs to be an atom
  though it'll automatically be converted to a string if the map is
  string keyed.
  """
  @spec put(map(), atom(), any()) :: map()
  def put(map, key, value) do
    key = cast_key(map, key)
    Map.put(map, key, value)
  end

  @doc """
  Puts a new value in a map. The provided needs to be an atom
  though it'll automatically be converted to a string if the map is
  string keyed.
  """
  @spec put_new(map(), atom(), any()) :: map()
  def put_new(map, key, value) do
    key = cast_key(map, key)
    Map.put_new(map, key, value)
  end

  @doc """
  Puts a new lazy value in a map. The provided needs to be an atom
  though it'll automatically be converted to a string if the map is
  string keyed.
  """
  @spec put_new_lazy(map(), atom(), (-> any())) :: map()
  def put_new_lazy(map, key, value_function) do
    key = cast_key(map, key)
    Map.put_new_lazy(map, key, value_function)
  end

  @doc """
  Gets a value in a map from key. The provided needs to be an atom
  though it'll automatically be converted to a string if the map is
  string keyed.
  """
  @spec get(map(), atom()) :: any()
  def get(map, key) do
    key = cast_key(map, key)
    Map.get(map, key)
  end

  defp cast_key(map, key) do
    case key(map) do
      :string -> to_string(key)
      :atom -> key
    end
  end

  @doc """
  Gets a value from a key in a map with a default value. Unlike
  Map.get/3, this function will return the default even if the key
  exists but the value is nil.
  """
  @spec get_with_default(map(), any(), any()) :: any()
  def get_with_default(map, key, default) do
    case Map.get(map, key) do
      nil -> default
      value -> value
    end
  end

  defp key(map) do
    case Map.keys(map) do
      [binary | _] when is_binary(binary) -> :string
      _ -> :atom
    end
  end

  @doc "Maps map values within the same key"
  @spec map_values(map(), (any(), any() -> any())) :: map()
  def map_values(map, function) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      updated_value = function.({key, value})
      Map.put(acc, key, updated_value)
    end)
  end

  @doc "Updates a map value from its key only if it exists"
  @spec update_if_exists(map(), any(), (any() -> any())) :: map()
  def update_if_exists(map, key, function) do
    if Map.has_key?(map, key) do
      Map.update!(map, key, function)
    else
      map
    end
  end

  @doc "Takes only the given keys no matter the key type"
  @spec take(map(), [atom()]) :: map()
  def take(map, keys) do
    Enum.reduce(keys, %{}, fn key, acc ->
      value = get(map, key)
      Map.put(acc, key, value)
    end)
  end

  @doc "Renames a key"
  @spec rename(map(), any(), any(), any()) :: map()
  def rename(map, from, to, default \\ nil) do
    {value, map} = Map.pop(map, from, default)
    Map.put(map, to, value)
  end
end
