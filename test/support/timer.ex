defmodule Box.Support.Timer do
  @default_timer 10
  def wait_until(function, timer \\ @default_timer) do
    wait_until(function, 0, timer)
  end

  defp wait_until(_function, current_timer, max_timer) when current_timer >= max_timer do
    raise "Function never returned true"
  end

  defp wait_until(function, current_timer, max_timer) do
    function.()
  rescue
    ExUnit.AssertionError ->
      Process.sleep(100)
      wait_until(function, current_timer + 1, max_timer)
  end
end
