defmodule Box.Generator.CharactersTest do
  use Box.BaseCase

  alias Box.Generator.Characters

  describe "generate/1" do
    test "generates characters string" do
      assert Regex.match?(~r/^[abc]{8}$/, Characters.generate(characters: "abc", length: 8))
      assert Regex.match?(~r/^[%&*]{8}$/, Characters.generate(characters: "%&*", length: 8))
    end
  end
end
