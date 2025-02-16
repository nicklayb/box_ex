defmodule Box.Generator.Hexadecimal do
  @moduledoc """
  Generates a hexadecimal string.

  ## Options

  - `length`
  """
  @behaviour Box.Generator

  @hex_characters "abcdef0123456789"

  @impl Box.Generator
  def generate(options) do
    options
    |> Keyword.put(:characters, @hex_characters)
    |> Box.Generator.Characters.generate()
  end
end
