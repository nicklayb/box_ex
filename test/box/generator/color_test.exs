defmodule Box.Generator.ColorTest do
  use Box.BaseCase
  alias Box.Color
  alias Box.Generator.Color, as: ColorGenerator

  @retest_count 5
  describe "generate/1 :hsl" do
    test "generates hsl color" do
      test_and_retest(fn ->
        color = ColorGenerator.generate(type: :hsl)

        assert_hsl(color)
      end)
    end

    test "generates hsl color with alpha" do
      test_and_retest(fn ->
        test_range = 1..99

        color = ColorGenerator.generate(type: :hsl, alpha: test_range)

        assert color.alpha in test_range
        assert_hsl(color)
      end)
    end

    test "generates hsl color with fixed alpha" do
      color = ColorGenerator.generate(type: :hsl, alpha: 54)
      assert color.alpha == 54
      assert_hsl(color)
      color = ColorGenerator.generate(type: :hsl, alpha: 54..54)
      assert color.alpha == 54
      assert_hsl(color)
    end

    test "generates hsl color with fixed value" do
      assert %Color{format: :hsl, value: {10, 10, 10}} =
               ColorGenerator.generate(
                 type: :hsl,
                 hue: 10,
                 saturation: 10,
                 lightness: 10
               )

      assert %Color{format: :hsl, value: {10, 10, 10}} =
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
        color = ColorGenerator.generate(type: :rgb)
        assert_rgb(color)
      end)
    end

    test "generates rgb color with alpha" do
      test_and_retest(fn ->
        test_range = 1..99
        color = ColorGenerator.generate(type: :rgb, alpha: test_range)

        assert color.alpha in test_range

        assert_rgb(color)
      end)
    end

    test "generates rgb color with fixed alpha" do
      color = ColorGenerator.generate(type: :rgb, alpha: 86)
      assert_rgb(color)
      assert color.alpha == 86

      color = ColorGenerator.generate(type: :rgb, alpha: 54..54)
      assert_rgb(color)
      assert color.alpha == 54
    end

    test "generates rgb color with fixed value" do
      assert %Color{format: :rgb, value: {10, 10, 10}} =
               ColorGenerator.generate(
                 type: :rgb,
                 red: 10,
                 green: 10,
                 blue: 10
               )

      assert %Color{format: :rgb, value: {10, 10, 10}} =
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

  defp assert_rgb(%Color{format: format, alpha: alpha, value: {red, green, blue}}) do
    assert format == :rgb
    assert red in Color.range(:red)
    assert green in Color.range(:green)
    assert blue in Color.range(:blue)
    assert alpha in Color.range(:alpha)
  end

  defp assert_hsl(%Color{format: format, alpha: alpha, value: {hue, saturation, lightness}}) do
    assert format == :hsl
    assert hue in Color.range(:hue)
    assert saturation in Color.range(:saturation)
    assert lightness in Color.range(:lightness)
    assert alpha in Color.range(:alpha)
  end
end
