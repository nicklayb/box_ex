defmodule Box.Ecto.DynamicType do
  use Ecto.ParameterizedType

  @type decoded :: any()
  @type input :: String.t()

  @callback decode(input()) :: {:ok, decoded()} | :error
  @callback encode(decoded()) :: {:ok, input()} | :error

  def type(_params), do: :string

  def init(opts) do
    decoder = Keyword.fetch!(opts, :decoder)
    %{decoder: decoder}
  end

  def cast(data, %{decoder: decoder}) when is_binary(data) do
    decoder.decode(data)
  rescue
    _ ->
      :error
  end

  def cast(data, %{decoder: decoder}) do
    case decoder.encode(data) do
      {:ok, _} ->
        {:ok, data}

      _ ->
        :error
    end
  end

  def load(nil, _, _), do: {:ok, nil}

  def load(data, _loader, %{decoder: decoder}) do
    decoder.decode(data)
  rescue
    _ ->
      :error
  end

  def dump(nil, _dumper, _), do: {:ok, nil}

  def dump(data, _dumper, %{decoder: decoder}) do
    decoder.encode(data)
  rescue
    _ ->
      :error
  end

  def equal?(left, right, _params) do
    left == right
  end
end
