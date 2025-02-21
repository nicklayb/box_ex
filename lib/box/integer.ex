defmodule Box.Integer do
  @units [
    ms: 1000,
    s: 1000,
    m: 60,
    h: 60,
    d: 24
  ]

  @spec to_duration_string(integer(), integer()) :: String.t()
  def to_duration_string(start_time, end_time) do
    {duration, unit} =
      Enum.reduce_while(@units, end_time - start_time, fn {unit, divider}, duration ->
        if duration / divider >= 1 do
          {:cont, duration / divider}
        else
          {:halt, {duration, unit}}
        end
      end)

    "#{round(duration)}#{unit}"
  end
end
