defmodule Box.Integer do
  @units [
    ms: 1000,
    s: 1000,
    m: 60,
    h: 60,
    d: 24
  ]
  @unit_keys Keyword.keys(@units)

  @spec to_duration_string(integer()) :: String.t()
  def to_duration_string(start_time, end_time), do: to_duration_string(end_time - start_time)

  @spec to_duration_string(integer()) :: String.t()
  def to_duration_string(time) when time < 1000 do
    to_string(time)
  end

  def to_duration_string(time) do
    {duration, unit} =
      Enum.reduce_while(@units, {time, :ms}, fn {unit, divider}, {duration, current_unit} ->
        if duration / divider >= 1 do
          {:cont, {duration / divider, unit}}
        else
          {:halt, {duration, current_unit}}
        end
      end)

    "#{round(duration)}#{unit}"
  end

  def to_duration_string_with_unit(integer, :us), do: to_duration_string(integer)

  def to_duration_string_with_unit(integer, unit) when unit in @unit_keys do
    multiplier =
      Enum.reduce_while(@units, 1, fn {current_unit, multiplier}, acc ->
        if current_unit == unit do
          {:halt, acc * multiplier}
        else
          {:cont, acc * multiplier}
        end
      end)

    to_duration_string(integer * multiplier)
  end

  @duration_string_regex ~r/^([0-9]+)([a-z]{1,2})?$/
  @doc "Converts a duration string like 1s to milliseconds"
  @spec from_duration_string(String.t()) :: non_neg_integer()
  def from_duration_string(string) do
    case Regex.scan(@duration_string_regex, string) do
      [[_, amount, unit]] ->
        from_duration_string(amount, unit)

      [[_, amount]] ->
        from_duration_string(amount, "")

      _ ->
        raise "Invalid string #{inspect(string)}"
    end
  end

  defp from_duration_string(amount, unit) when is_binary(amount) and is_binary(unit) do
    amount_int = String.to_integer(amount)
    unit_atom = cast_unit(unit)
    from_duration_string(amount_int, unit_atom)
  end

  defp from_duration_string(amount, :us) when is_integer(amount), do: amount

  defp from_duration_string(amount, unit) when is_integer(amount) and unit in @unit_keys do
    multiplier =
      Enum.reduce_while(@units, 1, fn {current_unit, current_multiplier}, multiplier ->
        if unit == current_unit do
          {:halt, multiplier * current_multiplier}
        else
          {:cont, multiplier * current_multiplier}
        end
      end)

    amount * multiplier
  end

  defp cast_unit(""), do: {:ok, :us}

  defp cast_unit(string) do
    case Enum.find(@unit_keys, &(to_string(&1) == string)) do
      nil ->
        raise "Invalid unit #{inspect(string)}"

      unit ->
        unit
    end
  end
end
