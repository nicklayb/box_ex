defmodule Box.Generator.Color do
  @moduledoc """
  Generates an RGB(A) string.

  ## Options

  - `alpha`: Range of possible alpha to generate. Range is expected to be from integer value like `0..100` in order to have from 0.0 to 1.0
  - `type`: `:hsl`, `:hex` or `:rgb`
  """
  @behaviour Box.Generator

  @impl Box.Generator
  def generate(options) do
    {color_type, options} = Keyword.pop!(options, :type)
    alpha_option = Keyword.get(options, :alpha)

    alpha = generate_alpha(color_type, alpha_option)

    generate(color_type, alpha, options)
  end

  @hex_color_length 6
  def generate(:hex, alpha, options) do
    options
    |> Keyword.put(:length, @hex_color_length)
    |> Box.Generator.Hexadecimal.generate()
    |> apply_with_alpha(alpha, &(&1 <> &2))
  end

  @degree 0..359
  @percent 0..100
  def generate(:hsl, alpha, options) do
    hue = Enum.random(@degree)
    saturation = Enum.random(@percent)
    lightness = Enum.random(@percent)

    "hsl(#{hue}, #{staturation}%, #{lightness}%#{alpha})"
  end

  @hex_range 0..255
  def generate(:rgb, alpha, options) do
    red = Enum.random(@hex_range)
    green = Enum.random(@hex_range)
    blue = Enum.random(@hex_range)

    "rgb(#{red}, #{green}, #{blue}#{alpha})"
  end

  defp generate_alpha(_, nil), do: ""

  defp generate_alpha(:hex, range) do
    range
    |> Enum.randome()
    |> Integer.to_string(16)
  end

  defp generate_alpha(rgb_or_hsl, range) when rgb_or_hsl in [:hsl, :rgb] do
    " / #{Enum.random(range) / 100}"
  end

  defp apply_with_alpha(string, nil, _), do: string
  defp apply_with_alpha(string, alpha, function), do: function.(string, alpha)
end
