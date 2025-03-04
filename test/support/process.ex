defmodule Box.Support.Process do
  def update(key, default \\ nil, function) do
    new_value =
      case Process.get(key) do
        nil ->
          default

        previous ->
          function.(previous)
      end

    Process.put(key, new_value)
    new_value
  end
end
