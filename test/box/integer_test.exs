defmodule Box.IntegerTest do
  use Box.BaseCase

  @examples %{
    "56" => 56,
    "3ms" => 3000,
    "4s" => :timer.seconds(4) * 1000,
    "2m" => :timer.minutes(2) * 1000,
    "5h" => :timer.hours(5) * 1000,
    "7d" => :timer.hours(24) * 7 * 1000
  }
  describe "to_duration_string/2" do
    for {string, int} <- @examples do
      test "converts #{int} to #{string}" do
        assert unquote(string) == Box.Integer.to_duration_string(unquote(int))
      end
    end
  end

  describe "from_duration_string/1" do
    for {string, int} <- @examples do
      test "parse #{string} as #{int} string" do
        assert unquote(int) == Box.Integer.from_duration_string(unquote(string))
      end
    end
  end
end
