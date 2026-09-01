defmodule Box.DataFilter do
  @type accumulator() :: any()

  @type filter() :: struct()

  @type key() :: atom()

  @type params() :: map()

  @callback cast(filter(), atom(), key()) :: struct() | filter()

  @callback apply(filter(), accumulator(), key(), any()) :: accumulator()

  @callback to_query(filter(), key(), any()) ::
              String.t() | nil | :ignore | {atom() | String.t(), String.t()}

  defmacro __using__(options) do
    quote do
      alias Box.DataFilter
      @behaviour Box.DataFilter

      @struct_fields unquote(options)
                     |> Keyword.fetch!(:fields)
                     |> Enum.map(fn {name, options} ->
                       {name, Keyword.get(options, :default)}
                     end)

      @fields Keyword.keys(@struct_fields)

      defstruct [{:__data_filter__, true} | @struct_fields]

      alias __MODULE__, as: Filter

      def fields, do: @fields

      def new, do: %__MODULE__{}

      def new(params) do
        DataFilter.cast_filter(new(), params)
      end

      def set(%__MODULE__{} = filter, key, value) do
        DataFilter.cast(filter, key, value)
      end

      def update(%__MODULE__{} = filter, params) do
        DataFilter.cast_filter(filter, params)
      end

      def apply_filter(query, %__MODULE__{} = filter) do
        DataFilter.apply_filter(query, filter)
      end

      def to_query_params(%__MODULE__{} = filter, options \\ []) do
        DataFilter.to_query_params(filter, options)
      end

      def to_query_string(%__MODULE__{} = filter, options \\ []) do
        DataFilter.to_query_string(filter, options)
      end

      def reduce_fields(%__MODULE__{} = filter, accumulator, function) do
        Enum.reduce(fields(), accumulator, fn key, acc ->
          function.({key, Map.fetch!(filter, key)}, acc)
        end)
      end
    end
  end

  @doc "Casts filter from a params set (can be either strings or atoms)"
  @spec cast_filter(filter(), params()) :: filter()
  def cast_filter(%filter_module{__data_filter__: true} = filter, params) do
    Enum.reduce(params, filter, fn {key, value}, acc ->
      case cast_key(filter_module, key) do
        nil ->
          acc

        key_atom ->
          cast(acc, key_atom, value)
      end
    end)
  end

  defp cast_key(_filter_module, key) when is_atom(key), do: key

  defp cast_key(filter_module, string_key) do
    Enum.find(filter_module.fields(), fn field_name ->
      to_string(field_name) == string_key
    end)
  end

  @doc "Casts filter from a key (can be either strings or atoms) and a value"
  @spec cast(filter(), key(), any()) :: filter()
  def cast(%filter_module{__data_filter__: true} = filter, key, raw_value) do
    case filter_module.cast(filter, key, raw_value) do
      %^filter_module{} = new_filter -> new_filter
      value -> %{filter | key => value}
    end
  end

  @doc "Applies filter over accumulator"
  @spec apply_filter(accumulator(), filter()) :: accumulator()
  def apply_filter(query, %filter_module{__data_filter__: true} = filter) do
    filter_module.reduce_fields(filter, query, fn {field, value}, acc ->
      filter_module.apply(filter, acc, field, value)
    end)
  end

  @doc "Checks if a field is a valid one"
  @spec valid_field?(filter(), atom()) :: boolean
  def valid_field?(%filter_module{__data_filter__: true}, field),
    do: field in filter_module.fields()

  def to_query_params(%filter_module{__data_filter__: true} = filter, options) do
    accumulator = Keyword.get(options, :accumulator, %{})
    skipped_fields = Keyword.get(options, :skip, [])

    filter_module.reduce_fields(filter, accumulator, fn {field, value}, acc ->
      if field in skipped_fields do
        acc
      else
        case filter_module.to_query(filter, field, value) do
          :ignore -> acc
          {key, value} when is_atom(key) -> Map.put(acc, to_string(key), value)
          {key, value} -> Map.put(acc, key, value)
          value -> Map.put(acc, to_string(field), value)
        end
      end
    end)
  end

  def to_query_string(%_{__data_filter__: true} = filter, options) do
    filter
    |> to_query_params(options)
    |> URI.encode_query()
  end
end
