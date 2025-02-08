defmodule Box.ListTest do
  use Box.BaseCase

  describe "at_least?/2" do
    test "true if list as at least x elements" do
      assert Box.List.at_least?([], 0)
      refute Box.List.at_least?([], 3)
      refute Box.List.at_least?([1], 3)
      refute Box.List.at_least?([1, 2], 3)
      assert Box.List.at_least?([1, 2, 3], 3)
      assert Box.List.at_least?([1, 2, 3, 4], 3)
      assert Box.List.at_least?([1, 2, 3, 4, 5], 3)
    end
  end
end
