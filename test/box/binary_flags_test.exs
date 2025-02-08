defmodule Box.BinaryFlagsTest do
  use Box.BaseCase

  require Assertions

  @flags [
    :first_flag,
    :second_flag,
    :third_flag
  ]

  @flag_conversions %{
    0 => [],
    1 => [:first_flag],
    2 => [:second_flag],
    3 => [:first_flag, :second_flag],
    4 => [:third_flag],
    5 => [:first_flag, :third_flag],
    6 => [:second_flag, :third_flag],
    7 => [:first_flag, :second_flag, :third_flag]
  }

  describe "to_integer/2" do
    test "converts flags to integer" do
      Box.BinaryFlags.EctoType.type([])

      Enum.each(@flag_conversions, fn {expected, flags} ->
        assert expected == Box.BinaryFlags.to_integer(@flags, flags)
      end)
    end
  end

  describe "to_flags/2" do
    test "converts integer to flag list" do
      Enum.each(@flag_conversions, fn {integer, expected_flags} ->
        Assertions.assert_lists_equal(expected_flags, Box.BinaryFlags.to_flags(@flags, integer))
      end)
    end

    test "filters out invalid flags from list" do
      Enum.each(@flag_conversions, fn {_, flags} ->
        flags_with_invalid = Enum.shuffle([:invalid_flag | flags])
        Assertions.assert_lists_equal(flags, Box.BinaryFlags.to_flags(@flags, flags_with_invalid))
      end)
    end
  end
end
