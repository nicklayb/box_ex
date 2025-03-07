defmodule Box.KeywordTest do
  use Box.BaseCase

  describe "rename/3" do
    test "renames key in a keyword list if present" do
      assert [new: 1] == Box.Keyword.rename([old: 1], :old, :new)
      assert [old: 1] == Box.Keyword.rename([old: 1], :dragon, :monster)
    end
  end
end
