defmodule Box.Generator.ColorTest do
  use Box.BaseCase
  alias Box.Generator.Color, as: ColorGenerator

  @retest_count 5
  describe "generate/1 :hex" do
    test "generates hex color" do
      test_and_retest(fn ->
        hex = ColorGenerator.generate(type: :hex)

        assert String.length(hex) == 6

        assert Regex.match?(~r/^[A-Z0-9]{6}$/, hex)
      end)
    end

    test "generates hex color with alpha" do
      test_and_retest(fn ->
        hex = ColorGenerator.generate(type: :hex, alpha: 1..255)

        assert Regex.match?(~r/^[A-Z0-9]{8}$/, hex)
      end)
    end

    test "generates hex color with fixed alpha" do
      alpha = "0F"
      alpha_integer = String.to_integer(alpha, 16)
      hex = ColorGenerator.generate(type: :hex, alpha: alpha_integer..alpha_integer)

      assert Regex.match?(~r/^[A-Z0-9]{6}0F$/, hex)

      alpha = "3B"
      alpha_integer = String.to_integer(alpha, 16)
      hex = ColorGenerator.generate(type: :hex, alpha: alpha_integer..alpha_integer)

      assert Regex.match?(~r/^[A-Z0-9]{6}3B$/, hex)
    end
  end

  describe "generate/1 :hsl" do
    test "generates hsl color" do
      test_and_retest(fn ->
        hsl = ColorGenerator.generate(type: :hsl)
        assert Regex.match?(~r/hsl\([0-9]{1,3}, [0-9]{1,3}%, [0-9]{1,3}%\)/, hsl)
      end)
    end

    test "generates hsl color with alpha" do
      test_and_retest(fn ->
        hsl = ColorGenerator.generate(type: :hsl, alpha: 1..100)
        assert Regex.match?(~r/hsl\([0-9]{1,3}, [0-9]{1,3}%, [0-9]{1,3}% \/ [0-9]\.[0-9]+\)/, hsl)
      end)
    end

    test "generates hsl color with fixed alpha" do
      hsl = ColorGenerator.generate(type: :hsl, alpha: 100..100)
      assert Regex.match?(~r/hsl\([0-9]{1,3}, [0-9]{1,3}%, [0-9]{1,3}% \/ 1\.0\)/, hsl)
      hsl = ColorGenerator.generate(type: :hsl, alpha: 54..54)
      assert Regex.match?(~r/hsl\([0-9]{1,3}, [0-9]{1,3}%, [0-9]{1,3}% \/ 0\.54\)/, hsl)
    end

    test "generates hsl color with fixed value" do
      assert "hsl(10, 10%, 10%)" =
               ColorGenerator.generate(
                 type: :hsl,
                 hue: 10,
                 saturation: 10,
                 lightness: 10
               )

      assert "hsl(10, 10%, 10%)" =
               ColorGenerator.generate(
                 type: :hsl,
                 hue: 10..10,
                 saturation: 10..10,
                 lightness: 10..10
               )
    end
  end

  describe "generate/1 :rgb" do
    test "generates rgb color" do
      test_and_retest(fn ->
        rgb = ColorGenerator.generate(type: :rgb)
        assert Regex.match?(~r/rgb\([0-9]{1,3}, [0-9]{1,3}, [0-9]{1,3}\)/, rgb)
      end)
    end

    test "generates rgb color with alpha" do
      test_and_retest(fn ->
        rgb = ColorGenerator.generate(type: :rgb, alpha: 1..100)
        assert Regex.match?(~r/rgb\([0-9]{1,3}, [0-9]{1,3}, [0-9]{1,3} \/ [0-9]\.[0-9]+\)/, rgb)
      end)
    end

    test "generates rgb color with fixed alpha" do
      rgb = ColorGenerator.generate(type: :rgb, alpha: 100..100)
      assert Regex.match?(~r/rgb\([0-9]{1,3}, [0-9]{1,3}, [0-9]{1,3} \/ 1\.0\)/, rgb)
      rgb = ColorGenerator.generate(type: :rgb, alpha: 54..54)
      assert Regex.match?(~r/rgb\([0-9]{1,3}, [0-9]{1,3}, [0-9]{1,3} \/ 0\.54\)/, rgb)
    end

    test "generates rgb color with fixed value" do
      assert "rgb(10, 10, 10)" =
               ColorGenerator.generate(
                 type: :rgb,
                 red: 10,
                 green: 10,
                 blue: 10
               )

      assert "rgb(10, 10, 10)" =
               ColorGenerator.generate(
                 type: :rgb,
                 red: 10..10,
                 green: 10..10,
                 blue: 10..10
               )
    end
  end

  defp test_and_retest(function) do
    Enum.each(1..@retest_count, fn _ -> function.() end)
  end
end
