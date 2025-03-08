defmodule Box.StringTest do
  use Box.BaseCase

  describe "to_slug/2" do
    test "slugifies" do
      assert "my-super-slug" == Box.String.to_slug("My super slug")
      assert "my_super_slug" == Box.String.to_slug("My super slug", separator: "_")

      assert "my_super_slug" ==
               Box.String.to_slug("My super slug", separator: "_", incrementer: nil)

      assert "my-super-slug-2" == Box.String.to_slug("My super slug", incrementer: 2)

      assert "my_super_slug_2" ==
               Box.String.to_slug("My super slug", separator: "_", incrementer: 2)
    end
  end
end
