defmodule Box.Generator.Color do
  @moduledoc """
  Generates an RGB(A) string.

  ## Options

  - `alpha`: Range of possible alpha to generate. Range is expected to be from integer value like `0..100` in order to have from 0.0 to 1.0
  - `type`: `:hsl`, `:hex` or `:rgb`

  ### Type specific options

  #### RGB

  - `red`: Range to pick for red
  - `blue`: Range to pick for blue
  - `green`: Range to pick for green

  #### HSL

  - `hue`: Range to pick for hue
  - `saturation`: Range to pick for saturation
  - `lightness`: Range to pick for lightness
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
    |> String.upcase()
  end

  @degree 0..359
  @percent 0..100
  def generate(:hsl, alpha, options) do
    [hue, saturation, lightness] =
      Enum.map([hue: @degree, saturation: @percent, lightness: @percent], fn {parameter, default} ->
        options
        |> Keyword.get(parameter, default)
        |> Enum.random()
      end)

    "hsl(#{hue}, #{saturation}%, #{lightness}%#{alpha})"
  end

  @hex_range 0..255
  def generate(:rgb, alpha, options) do
    [red, blue, green] =
      Enum.map([:red, :green, :blue], fn color ->
        options
        |> Keyword.get(color, @hex_range)
        |> Enum.random()
      end)

    "rgb(#{red}, #{green}, #{blue}#{alpha})"
  end

  defp generate_alpha(_, nil), do: ""

  defp generate_alpha(:hex, range) do
    range
    |> Enum.random()
    |> Integer.to_string(16)
    |> String.pad_leading(2, "0")
  end

  defp generate_alpha(rgb_or_hsl, range) when rgb_or_hsl in [:hsl, :rgb] do
    " / #{Enum.random(range) / 100}"
  end

  defp apply_with_alpha(string, nil, _), do: string
  defp apply_with_alpha(string, alpha, function), do: function.(string, alpha)
end
