defmodule Box.Generator.Color do
  @moduledoc """
  Generates an RGB(A) string.

  ## Options

  - `alpha`: Range of possible alpha to generate. Range is expected to be from integer value like `0..100` in order to have from 0.0 to 1.0. Fixed value can be passed as int
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
  alias Box.Color
  @behaviour Box.Generator

  @impl Box.Generator
  def generate(options) do
    {color_type, options} = Keyword.pop!(options, :type)
    alpha_option = Keyword.get(options, :alpha, 100)

    generate(color_type, random(alpha_option), options)
  end

  def generate(:hsl, alpha, options) do
    [hue, saturation, lightness] =
      Enum.map([:hue, :saturation, :lightness], fn parameter ->
        options
        |> Keyword.get_lazy(parameter, fn -> Color.range(parameter) end)
        |> random()
      end)

    {hue, saturation, lightness}
    |> Color.hsl!(alpha)
    |> stringify(options)
  end

  def generate(:rgb, alpha, options) do
    [red, blue, green] =
      Enum.map([:red, :green, :blue], fn color ->
        options
        |> Keyword.get_lazy(color, fn -> Color.range(color) end)
        |> random()
      end)

    {red, blue, green}
    |> Color.rgb!(alpha)
    |> stringify(options)
  end

  defp random(integer) when is_integer(integer), do: integer
  defp random(range), do: Enum.random(range)

  defp stringify(%Color{} = color, options) do
    case Keyword.get(options, :format, :raw) do
      :raw -> color
      :hex -> Color.to_hex(color)
      :hsl -> Color.to_hsl(color)
      :rgb -> Color.to_rgb(color)
    end
  end
end
