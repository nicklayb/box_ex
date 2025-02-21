defmodule Box.Timer do
  def now, do: System.system_time(:millisecond)
end
