defmodule Box.ColorTest do
  use Box.BaseCase

  alias Box.Color

  describe "rgb_from_hex!/2" do
    test "creates rgb from hex" do
      red = 125
      green = 110
      blue = 50

      hex = Base.encode16(<<125, 110, 50>>)

      assert %Color{format: :rgb, value: {^red, ^green, ^blue}, alpha: 100} =
               Color.rgb_from_hex!(hex)

      assert %Color{format: :rgb, value: {79, 193, 59}, alpha: 100} =
               Color.rgb_from_hex!("4FC13B")

      assert %Color{format: :rgb, value: {79, 193, 59}, alpha: 100} =
               Color.rgb_from_hex!("4fc13b")

      assert %Color{format: :rgb, value: {79, 193, 59}, alpha: 33} =
               Color.rgb_from_hex!("4FC13B54")
    end
  end

  describe "rgb!/2" do
    test "creates rgb" do
      red = 76
      blue = 43
      green = 90

      %Color{format: :rgb, value: {^red, ^green, ^blue}, alpha: 100} =
        Color.rgb!({red, green, blue})

      %Color{format: :rgb, value: {^red, ^green, ^blue}, alpha: 23} =
        Color.rgb!({red, green, blue}, 23)
    end
  end

  describe "hsl!/2" do
    test "creates hsl" do
      hue = 76
      saturation = 90
      lightness = 43

      %Color{format: :hsl, value: {^hue, ^saturation, ^lightness}, alpha: 100} =
        Color.hsl!({hue, saturation, lightness})

      %Color{format: :hsl, value: {^hue, ^saturation, ^lightness}, alpha: 23} =
        Color.hsl!({hue, saturation, lightness}, 23)
    end
  end

  describe "to_rgb/1" do
    test "rgb remains rgb" do
      color = Color.rgb!({120, 100, 30})
      assert color == Color.to_rgb(color)
    end

    test "converts achromatic hsl to rgb" do
      color = Color.hsl!({231, 0, 70})

      assert %Color{format: :rgb, value: {same, same, same}} = Color.to_rgb(color)
    end

    test "converts hsl to rgb" do
      base_color = Color.rgb!({120, 100, 30})

      hsl_color = Color.to_hsl(base_color)

      assert equal_with_threshold(base_color, Color.to_rgb(hsl_color))
      base_color = Color.rgb!({100, 30, 120})

      hsl_color = Color.to_hsl(base_color)

      assert equal_with_threshold(base_color, Color.to_rgb(hsl_color))
      base_color = Color.rgb!({234, 252, 241})

      hsl_color = Color.to_hsl(base_color)

      assert equal_with_threshold(base_color, Color.to_rgb(hsl_color))
    end
  end

  describe "to_hsl/1" do
    test "hsl remains hsl" do
      color = Color.hsl!({120, 100, 30})
      assert color == Color.to_hsl(color)
    end

    test "converts achromatic rgb to hsl" do
      color = Color.rgb!({56, 56, 56})

      assert %Color{format: :hsl, value: {0, 0, _}} = Color.to_hsl(color)
    end

    test "converts rgb to hsl" do
      base_color = Color.hsl!({120, 100, 30})

      rgb_color = Color.to_rgb(base_color)

      assert equal_with_threshold(base_color, Color.to_hsl(rgb_color))
    end
  end

  describe "hsl?/1" do
    test "checks if hsl" do
      assert Color.hsl?(Color.hsl!({123, 23, 32}))
      refute Color.hsl?(Color.rgb!({123, 23, 32}))
    end
  end

  describe "rgb?/1" do
    test "checks if rgb" do
      assert Color.rgb?(Color.rgb!({123, 23, 32}))
      refute Color.rgb?(Color.hsl!({123, 23, 32}))
    end
  end

  describe "to_css/1" do
    test "converts rgb without alpha" do
      color = Color.rgb!({32, 43, 54})
      assert "rgb(32, 43, 54)" = Color.to_css(color)
    end

    test "converts rgb with alpha" do
      color = Color.rgb!({32, 43, 54}, 67)
      assert "rgb(32, 43, 54, 0.67)" = Color.to_css(color)
      color = Color.rgb!({32, 43, 54}, 100)
      assert "rgb(32, 43, 54)" = Color.to_css(color)
      assert "rgb(32, 43, 54, 1.0)" = Color.to_css(color, with_alpha: true)
    end

    test "converts hsl without alpha" do
      color = Color.hsl!({32, 43, 54})
      assert "hsl(32, 43%, 54%)" = Color.to_css(color)
    end

    test "converts hsl with alpha" do
      color = Color.hsl!({32, 43, 54}, 67)
      assert "hsl(32, 43%, 54%, 0.67)" = Color.to_css(color)
      color = Color.hsl!({32, 43, 54}, 100)
      assert "hsl(32, 43%, 54%)" = Color.to_css(color)
      assert "hsl(32, 43%, 54%, 1.0)" = Color.to_css(color, with_alpha: true)
    end
  end

  describe "parse!/1" do
    test "parse rgb string" do
      assert %Color{format: :rgb, value: {121, 234, 32}, alpha: 100} =
               Color.parse!("rgb(121, 234, 32)")

      assert %Color{format: :rgb, value: {121, 234, 32}, alpha: 34} =
               Color.parse!("rgba(121, 234, 32, 0.34)")

      assert %Color{format: :rgb, value: {121, 234, 32}, alpha: 34} =
               Color.parse!("rgb(121, 234, 32, 0.34)")

      assert %Color{format: :rgb, value: {121, 234, 32}, alpha: 34} =
               Color.parse!("rgb(121, 234, 32, 34%)")
    end

    test "parse hsl string" do
      assert %Color{format: :hsl, value: {121, 34, 32}, alpha: 100} =
               Color.parse!("hsl(121, 34%, 32%)")

      assert %Color{format: :hsl, value: {121, 34, 32}, alpha: 34} =
               Color.parse!("hsl(121, 34%, 32%, 0.34)")

      assert %Color{format: :hsl, value: {121, 100, 32}, alpha: 34} =
               Color.parse!("hsl(121, 100%, 32%, 34%)")
    end

    test "parse hex string" do
      assert %Color{format: :rgb, value: {252, 50, 74}, alpha: 100} = Color.parse!("#fc324a")
      assert %Color{format: :rgb, value: {252, 50, 74}, alpha: 100} = Color.parse!("fc324a")
      assert %Color{format: :rgb, value: {252, 50, 74}, alpha: 100} = Color.parse!("FC324A")
      assert %Color{format: :rgb, value: {252, 50, 74}, alpha: 50} = Color.parse!("FC324A7F")
    end
  end

  @threshold 2
  defp equal_with_threshold(%Color{value: left}, %Color{value: right}, threshold \\ @threshold) do
    pairs =
      left
      |> Tuple.to_list()
      |> Enum.zip(Tuple.to_list(right))

    Enum.all?(pairs, fn {left, right} ->
      abs(left - right) <= threshold
    end)
  end
end
