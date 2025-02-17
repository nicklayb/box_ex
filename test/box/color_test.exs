defmodule Box.ColorTest do
  use Box.BaseCase

  alias Box.Color

  describe "rgb_from_hex!/2" do
    test "creates rgb from hex" do
      red = 125
      green = 110
      blue = 50

      hex = Base.encode16(<<red, green, blue>>)
      assert %Color{format: :rgb, value: {^red, ^green, ^blue}} = Color.rgb_from_hex!(hex)
    end
  end
end
