defmodule Box.HtmlTest do
  use Box.BaseCase

  alias Box.Html

  describe "class/2" do
    test "generates class list" do
      assert "" == Html.class("")
      assert "" == Html.class("", "")
      assert "class" == Html.class("class")
      assert "class" == Html.class("class", nil)
      assert "class" == Html.class("class", "")
      assert "class" == Html.class("class", [])
      assert "class" == Html.class("class", [""])
      assert "class other" == Html.class("class", "other")
      assert "class other another" == Html.class("class", ["other", "another"])

      assert "class other" == Html.class("class", [{true, "other"}])
      assert "class" == Html.class("class", [{false, "other"}])
      assert "class other" == Html.class("class", [{true, "other", "when-false"}])
      assert "class when-false" == Html.class("class", [{false, "other", "when-false"}])

      assert "class other" == Html.class("class", {true, "other"})
      assert "class" == Html.class("class", {false, "other"})
      assert "class other" == Html.class("class", {true, "other", "when-false"})
      assert "class when-false" == Html.class("class", {false, "other", "when-false"})

      assert "class other" == Html.class("class", {fn -> true end, "other"})
      assert "class" == Html.class("class", {fn -> false end, "other"})
      assert "class other" == Html.class("class", {fn -> true end, "other", "when-false"})
      assert "class when-false" == Html.class("class", {fn -> false end, "other", "when-false"})
    end
  end

  describe "titleize/1" do
    test "titleize a snake case value either as string or atom" do
      assert "This is titleized" == Html.titleize(:this_is_titleized)
      assert "This is titleized" == Html.titleize("this_is_titleized")
    end
  end
end
