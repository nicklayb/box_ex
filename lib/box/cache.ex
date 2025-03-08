defmodule Box.Cache do
  @moduledoc """
  Cache related function. They all depends on a Box.Cache server
  as this process will be the owner of the `:ets` table that holds
  the cached values.
  """

  @type cache :: atom()
  @type key :: atom() | tuple()
  @type value :: any()
  @type record_option :: {:expiration, integer() | :never}
  @type record :: {key(), value(), [record_option()]}
  @type match :: [tuple()]

  @doc """
  Select record from a cache using a match spec
  """
  @spec select(cache(), match()) :: [any()]
  def select(cache, match_spec) do
    :ets.select(cache, match_spec)
  end

  @all_spec [{:"$1", [], [:"$1"]}]

  @doc """
  Gets all record from a cache
  """
  @spec all(cache()) :: [record()]
  def all(cache) do
    select(cache, @all_spec)
  end

  @doc """
  Gets a record by its key
  """
  @spec get(cache(), key()) :: {:ok, value()} | {:error, :not_found}
  def get(cache, key) do
    case select(cache, get_by_key_spec(key)) do
      [] ->
        {:error, :not_found}

      [{value, options}] ->
        maybe_invalidate(cache, key, options)
        {:ok, value}
    end
  end

  @type input_record :: {key(), value()}
  @type insert_option :: {:ttl, non_neg_integer() | :infinity}
  @doc """
  Inserts one or multiple records in the database with the provided options.

  ## Available options

  - `ttl`: Time to live of the cache value.
  """
  @spec insert(cache(), input_record() | [input_record()], [insert_option()]) :: :ok
  def insert(cache, record_or_records, options \\ []) do
    GenServer.cast(cache, {:insert, record_or_records, options})
  end

  @doc """
  Deletes a record by its key from the cache
  """
  @spec delete(cache(), key()) :: :ok
  def delete(cache, key) do
    GenServer.cast(cache, {:delete, key})
  end

  defp maybe_invalidate(cache, key, options) do
    expiration = Keyword.get(options, :expiration, :never)

    if System.monotonic_time(:millisecond) >= expiration do
      delete(cache, key)
    end
  end

  defp get_by_key_spec(key) do
    key =
      case key do
        key when is_tuple(key) -> {key}
        _ -> key
      end

    [
      {{:"$1", :"$2", :"$3"}, [{:==, :"$1", key}], [{{:"$2", :"$3"}}]}
    ]
  end

  @type memoize_option :: {:cache_match, (any() -> boolean())}

  @doc """
  Memoizes a function in the given cache and under the given key. The function will
  be applied then cached under the key if the value matches the `cache_match` option.
  By default, the value won't be cached if it's `nil`, but one can override `cache_match`
  to alter this and use, for instance `&Box.Result.succeeded?/1` instead to only cache
  records that matches `{:ok, any()}` tuples.
  """
  @spec memoize(cache(), key(), [insert_option() | memoize_option()], (-> value())) :: value()
  def memoize(cache, key, options \\ [], function) do
    case get(cache, key) do
      {:ok, value} ->
        value

      {:error, :not_found} ->
        result = function.()

        if should_cache?(result, options) do
          insert(cache, {key, result}, options)
        end

        result
    end
  end

  defp should_cache?(result, options) do
    function = Keyword.get(options, :cache_match, &(not is_nil(&1)))
    function.(result)
  end
end
