defmodule Box.Generator.Base64Test do
  use Box.BaseCase

  alias Box.Generator.Base64

  describe "generate/1" do
    test "generates base64 string" do
      assert Regex.match?(~r/^[A-Za-z0-9+\/=]{8}$/, Base64.generate(length: 8))
    end
  end
end
