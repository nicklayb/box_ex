defmodule Box.Cache do
  def select(server, match_spec) do
    :ets.select(server, match_spec)
  end

  def get(server, key) do
    case select(server, get_by_key_spec(key)) do
      [] ->
        {:error, :not_found}

      [{value, options}] ->
        maybe_invalidate(server, key, options)
        {:ok, value}
    end
  end

  defp maybe_invalidate(server, key, options) do
    expiration = Keyword.get(options, :expiration, :infinity)

    if System.monotonic_time(:millisecond) >= expiration do
      Box.Cache.Server.delete(server, key)
    end
  end

  def get_by_key_spec(tuple) when is_tuple(tuple) do
    get_by_key_spec({tuple})
  end

  def get_by_key_spec(key) do
    [
      {{:"$1", :"$2", :"$3"}, [{:==, :"$1", key}], [{{:"$2", :"$3"}}]}
    ]
  end

  def memoize(server, key, options \\ [], function) do
    case get(server, key) do
      {:ok, value} ->
        value

      {:error, :not_found} ->
        result = function.()
        Box.Cache.Server.insert(server, {key, result}, options)
        result
    end
  end
end
