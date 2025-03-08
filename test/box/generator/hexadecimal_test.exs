defmodule Box.Generator.HexadecimalTest do
  use Box.BaseCase

  alias Box.Generator.Hexadecimal

  describe "generate/1" do
    test "generates hexadecimal string" do
      assert Regex.match?(~r/^[[:xdigit:]]{8}$/, Hexadecimal.generate(length: 8))
    end
  end
end
