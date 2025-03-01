defmodule Box.FractionTest do
  use Box.BaseCase

  alias Box.Fraction
  alias Phoenix.HTML.Safe, as: HtmlSafe

  describe "new/1" do
    test "creates from a tuple" do
      assert %Fraction{denominator: 10, numerator: 5} = Fraction.new({5, 10})
    end

    test "raises when denominator is 0" do
      assert_raise(ArgumentError, fn ->
        Fraction.new({1, 0})
      end)
    end

    test "creates from an integre" do
      assert %Fraction{denominator: 1, numerator: 6} = Fraction.new(6)
    end

    test "creates from a float" do
      assert %Fraction{denominator: 10, numerator: 15} = Fraction.new(1.5)
    end
  end

  describe "new/2" do
    test "creates from two integer" do
      assert %Fraction{denominator: 10, numerator: 5} = Fraction.new(5, 10)
    end

    test "raises when denominator is 0" do
      assert_raise(ArgumentError, fn ->
        Fraction.new(1, 0)
      end)
    end
  end

  describe "to_tuple/1" do
    test "converts fraction to tuple" do
      tuple_input = {1, 5}

      assert tuple_input
             |> Fraction.new()
             |> Fraction.to_tuple() ==
               tuple_input
    end
  end

  describe "to_float/1" do
    test "converts fraction to float" do
      float_input = 1.5

      assert float_input
             |> Fraction.new()
             |> Fraction.to_float() ==
               float_input
    end
  end

  describe "parse/1" do
    test "parses float format to fraction" do
      assert %Fraction{denominator: 10, numerator: 15} = Fraction.parse("1.5")
    end

    test "parses integer format to fraction" do
      assert %Fraction{denominator: 1, numerator: 5} = Fraction.parse("5")
    end

    test "parses fraction format to fraction" do
      assert %Fraction{denominator: 13, numerator: 22} = Fraction.parse("22/13")
    end

    test "raises when invalid format" do
      assert_raise(ArgumentError, fn -> Fraction.parse("Nope") end)
    end
  end

  describe "to_string/1" do
    test "converts integer fraction" do
      assert "43" =
               43
               |> Fraction.new()
               |> Fraction.to_string()
    end

    test "converts fraction over 1 as float" do
      assert "3.4" =
               3.4
               |> Fraction.new()
               |> Fraction.to_string()
    end

    test "converts fraction under 1 as fraction" do
      assert "7/11" =
               {7, 11}
               |> Fraction.new()
               |> Fraction.to_string()
    end

    test "converts full fraction as 1" do
      assert "1" =
               {11, 11}
               |> Fraction.new()
               |> Fraction.to_string()
    end
  end

  describe "compare/2" do
    test "compares as float" do
      assert :eq == Fraction.compare(Fraction.new(1, 1), Fraction.new(2, 2))
      assert :lt == Fraction.compare(Fraction.new(1, 2), Fraction.new(2, 1))
      assert :gt == Fraction.compare(Fraction.new(2, 1), Fraction.new(1, 2))
    end
  end

  describe "Phoenix.Html.Safe.to_iodata" do
    test "converts integer fraction" do
      assert "43" =
               43
               |> Fraction.new()
               |> HtmlSafe.to_iodata()
    end

    test "converts fraction over 1 as float" do
      assert "3.4" =
               3.4
               |> Fraction.new()
               |> HtmlSafe.to_iodata()
    end

    test "converts fraction under 1 as fraction" do
      assert "7/11" =
               {7, 11}
               |> Fraction.new()
               |> HtmlSafe.to_iodata()
    end

    test "converts full fraction as 1" do
      assert "1" =
               {11, 11}
               |> Fraction.new()
               |> HtmlSafe.to_iodata()
    end
  end
end
