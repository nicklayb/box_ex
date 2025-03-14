defmodule Box.Generator.Base64 do
  @moduledoc """
  Generates a base 64 URL safe
  """
  @behaviour Box.Generator

  @impl Box.Generator
  def generate(options) do
    length = Keyword.fetch!(options, :length)

    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end
end
