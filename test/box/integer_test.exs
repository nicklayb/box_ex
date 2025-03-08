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
  describe "to_duration_string/1" do
    for {string, int} <- @examples do
      test "converts #{int} to #{string}" do
        assert unquote(string) == Box.Integer.to_duration_string(unquote(int))
      end
    end
  end

  describe "to_duration_string/2" do
    test "converts a duration between two value" do
      assert "110ms" == Box.Integer.to_duration_string(102_121, 212_434)
    end
  end

  describe "from_duration_string/1" do
    for {string, int} <- @examples do
      test "parse #{string} as #{int} string" do
        assert unquote(int) == Box.Integer.from_duration_string(unquote(string))
      end
    end

    test "raises for invalid string" do
      assert_raise(RuntimeError, fn ->
        Box.Integer.from_duration_string("trois minutes")
      end)

      assert_raise(RuntimeError, fn ->
        Box.Integer.from_duration_string("14x")
      end)
    end
  end

  describe "to_duration_string_with_unit/2" do
    test "converts int to given units" do
      assert "123" == Box.Integer.to_duration_string_with_unit(123, :us)
      assert "123ms" == Box.Integer.to_duration_string_with_unit(123, :ms)
      assert "2m" == Box.Integer.to_duration_string_with_unit(120, :s)
      assert "30m" == Box.Integer.to_duration_string_with_unit(30, :m)
      assert "1h" == Box.Integer.to_duration_string_with_unit(60, :m)
      assert "12h" == Box.Integer.to_duration_string_with_unit(12, :h)
      assert "1d" == Box.Integer.to_duration_string_with_unit(24, :h)
    end
  end
end
