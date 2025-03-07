defmodule Box.Cache do
  @type cache :: atom()
  @type key :: atom() | tuple()
  @type value :: any()
  @type record_option :: {:expiration, integer() | :never}
  @type record :: {key(), value(), [record_option()]}
  @type match :: [tuple()]

  @spec select(cache(), match()) :: [any()]
  def select(cache, match_spec) do
    :ets.select(cache, match_spec)
  end

  @all_spec [{:"$1", [], [:"$1"]}]
  @spec all(cache()) :: [record()]
  def all(cache) do
    select(cache, @all_spec)
  end

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
  @spec insert(cache(), input_record() | [input_record()], [insert_option()]) :: :ok
  def insert(cache, record_or_records, options \\ []) do
    GenServer.cast(cache, {:insert, record_or_records, options})
  end

  @spec insert(cache(), key()) :: :ok
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
    case Keyword.get(options, :cache_match) do
      function when is_function(function, 1) ->
        function.(result)

      _ ->
        true
    end
  end
end
