defmodule Box.Generator.AlphanumericalTest do
  use Box.BaseCase

  alias Box.Generator.Alphanumerical

  describe "generate/1" do
    test "generates all string" do
      assert Regex.match?(~r/^[a-zA-Z0-9]{8}$/, Alphanumerical.generate(parts: :all, length: 8))
    end

    test "generates uppercase string" do
      assert Regex.match?(~r/^[A-Z]{8}$/, Alphanumerical.generate(parts: [:uppercase], length: 8))

      assert Regex.match?(
               ~r/^[^a-z]{8}$/,
               Alphanumerical.generate(parts: [:uppercase], length: 8)
             )

      assert Regex.match?(
               ~r/^[^0-9]{8}$/,
               Alphanumerical.generate(parts: [:uppercase], length: 8)
             )
    end

    test "generates lowercase string" do
      assert Regex.match?(~r/^[a-z]{8}$/, Alphanumerical.generate(parts: [:lowercase], length: 8))

      assert Regex.match?(
               ~r/^[^A-Z]{8}$/,
               Alphanumerical.generate(parts: [:lowercase], length: 8)
             )

      assert Regex.match?(
               ~r/^[^0-9]{8}$/,
               Alphanumerical.generate(parts: [:lowercase], length: 8)
             )
    end

    test "generates letter string" do
      assert Regex.match?(
               ~r/^[^0-9]{8}$/,
               Alphanumerical.generate(parts: [:uppercase, :lowercase], length: 8)
             )

      assert Regex.match?(
               ~r/^[a-zA-Z]{8}$/,
               Alphanumerical.generate(parts: [:uppercase, :lowercase], length: 8)
             )
    end

    test "generates numbers string" do
      assert Regex.match?(~r/^[0-9]{8}$/, Alphanumerical.generate(parts: [:numbers], length: 8))
      assert Regex.match?(~r/^[^a-z]{8}$/, Alphanumerical.generate(parts: [:numbers], length: 8))
      assert Regex.match?(~r/^[^A-Z]{8}$/, Alphanumerical.generate(parts: [:numbers], length: 8))
    end
  end
end
