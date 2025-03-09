defmodule Box.MaybeTest do
  use Box.BaseCase

  describe "map/2" do
    test "maps value over if not nil" do
      assert "HELLO" == Box.Maybe.map("hello", &String.upcase/1)
      assert nil == Box.Maybe.map(nil, &String.upcase/1)
    end
  end

  describe "with_default/2" do
    test "returns a default value when nil" do
      assert "all good" = Box.Maybe.with_default(nil, "all good")
      assert "hello" = Box.Maybe.with_default("hello", "all good")

      assert "hello" =
               Box.Maybe.with_default("hello", fn ->
                 Process.put(:called, true)
                 "all good"
               end)

      refute Process.get(:called)

      assert "all good" =
               Box.Maybe.with_default(nil, fn ->
                 Process.put(:called, true)
                 "all good"
               end)

      assert Process.get(:called)
    end
  end
end
