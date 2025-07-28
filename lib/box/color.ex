defmodule Box.Color do
  alias Box.Color

  @full_alpha 100
  defstruct [:format, :value, :source, alpha: @full_alpha]

  @type percent :: 0..100
  @type hex :: 0..255
  @type degree :: 0..359

  @type alpha :: percent()

  @type hsl :: {degree(), percent(), percent()}
  @type rgb :: {hex(), hex(), hex()}

  @type format :: :hsl | :rgb

  @type source :: format() | :hex

  @type t :: %Color{
          format: format(),
          value: hsl() | rgb(),
          source: source(),
          alpha: alpha()
        }

  @max_hex 255
  @max_percent 100
  @max_degree 359
  defguardp is_hex(value) when value >= 0 and value <= @max_hex
  defguardp is_percent(value) when value >= 0 and value <= @max_percent
  defguardp is_degree(value) when value >= 0 and value <= @max_degree

  @spec hsl!(hsl(), alpha()) :: t()
  def hsl!({hue, saturation, lightness}, alpha \\ @full_alpha)
      when is_degree(hue) and is_percent(saturation) and is_percent(lightness) and
             is_percent(alpha) do
    %Color{format: :hsl, value: {hue, saturation, lightness}, alpha: alpha}
  end

  @spec rgb!(rgb(), alpha()) :: t()
  def rgb!({red, green, blue}, alpha \\ @full_alpha)
      when is_hex(red) and is_hex(green) and is_hex(blue) and is_percent(alpha) do
    %Color{format: :rgb, value: {red, green, blue}, alpha: alpha}
  end

  @spec rgb_from_hex!(String.t()) :: t()
  def rgb_from_hex!(hex) do
    <<red::8, green::8, blue::8, maybe_alpha::binary>> =
      hex
      |> String.upcase()
      |> Base.decode16!()

    alpha =
      case maybe_alpha do
        <<alpha::8>> -> round(@max_percent * alpha / @max_hex)
        _ -> @full_alpha
      end

    rgb!({red, green, blue}, alpha)
  end

  @spec to_hsl(t()) :: t()
  def to_hsl(%Color{format: :hsl} = color), do: color

  def to_hsl(%Color{format: :rgb, value: {red, green, blue}} = color) do
    red = red / @max_hex
    green = green / @max_hex
    blue = blue / @max_hex
    max_value = max(red, max(green, blue))
    min_value = min(red, min(green, blue))
    lightness = (max_value + min_value) / 2

    if max_value == min_value do
      hsl!({0, 0, round(lightness * @max_percent)}, color.alpha)
    else
      delta = max_value - min_value

      saturation =
        if lightness > 0.5 do
          delta / (2 - max_value - min_value)
        else
          delta / (max_value + min_value)
        end

      hue =
        cond do
          max_value == red and green < blue ->
            (green - blue) / delta + 6

          max_value == red ->
            (green - blue) / delta

          max_value == green ->
            (blue - red) / delta + 2

          max_value == blue ->
            (red - green) / delta + 4
        end

      hue_int = round(hue / 6 * @max_degree)
      saturation_int = round(saturation * @max_percent)
      lightness_int = round(lightness * @max_percent)

      hsl!({hue_int, saturation_int, lightness_int}, color.alpha)
    end
  end

  @spec to_rgb(t()) :: t()
  def to_rgb(%Color{format: :rgb} = color), do: color

  @one_third 1 / 3
  def to_rgb(%Color{format: :hsl, value: {_hue, 0, lightness}} = color) do
    lightness = decimal_to_hex(lightness / @max_percent)
    rgb!({lightness, lightness, lightness}, color.alpha)
  end

  def to_rgb(%Color{format: :hsl, value: {hue, saturation, lightness}} = color) do
    hue = hue / @max_degree
    saturation = saturation / @max_percent
    lightness = lightness / @max_percent

    quotient =
      if lightness < 0.5 do
        lightness * (1 + saturation)
      else
        lightness + saturation - lightness * saturation
      end

    product = 2 * lightness - quotient

    {red, green, blue} = {
      hue_to_rgb(product, quotient, hue + @one_third),
      hue_to_rgb(product, quotient, hue),
      hue_to_rgb(product, quotient, hue - @one_third)
    }

    [red, green, blue] = Enum.map([red, green, blue], &decimal_to_hex/1)
    rgb!({red, green, blue}, color.alpha)
  end

  defp decimal_to_hex(decimal) do
    min(floor(decimal * (@max_hex + 1)), @max_hex)
  end

  defp hue_to_rgb(product, quotient, third) do
    third = if third < 0, do: third + 1, else: third
    third = if third > 1, do: third - 1, else: third

    cond do
      third < 1 / 6 -> product + (quotient - product) * 6 * third
      third < 1 / 2 -> quotient
      third < 2 / 3 -> product + (quotient + product) * (2 / 3 - third) * 6
      true -> product
    end
  end

  @spec put_alpha(t(), alpha()) :: t()
  def put_alpha(%Color{} = color, alpha) when is_percent(alpha) do
    %Color{color | alpha: alpha}
  end

  @type to_hex_option :: {:with_alpha, boolean()}
  @spec to_hex(t(), [to_hex_option()]) :: String.t()
  def to_hex(color, options \\ [])

  def to_hex(%Color{format: :rgb, value: {red, green, blue}, alpha: alpha}, options) do
    case {alpha, Keyword.get(options, :with_alpha, false)} do
      {@max_percent, false} ->
        Base.encode16(<<red, green, blue>>)

      {alpha, _} ->
        Base.encode16(<<red, green, blue, round(alpha * 255 / 100)>>)
    end
  end

  def to_hex(%Color{format: :hsl} = color, options) do
    color
    |> to_rgb()
    |> to_hex(options)
  end

  @spec hsl?(t()) :: boolean()
  def hsl?(%Color{format: format}), do: format == :hsl

  @spec rgb?(t()) :: boolean()
  def rgb?(%Color{format: format}), do: format == :rgb

  @type to_css_option :: {:with_alpha, boolean()}
  @spec to_css(t(), [to_css_option()]) :: String.t()
  def to_css(color, options \\ [])

  def to_css(%Color{source: :hex} = color, options) do
    to_hex(color, options)
  end

  def to_css(%Color{source: :rgb} = color, options) do
    to_css_rgb(color, options)
  end

  def to_css(%Color{source: :hsl} = color, options) do
    to_css_hsl(color, options)
  end

  def to_css(%Color{format: :hsl} = color, options) do
    to_css_hsl(color, options)
  end

  def to_css(%Color{format: :rgb} = color, options) do
    to_css_rgb(color, options)
  end

  def to_css_hsl(%Color{value: {hue, saturation, lightness}, alpha: alpha}, options) do
    "hsl(#{hue}, #{saturation}%, #{lightness}%#{alpha_to_string(alpha, options)})"
  end

  def to_css_rgb(%Color{value: {red, green, blue}, alpha: alpha}, options) do
    "rgb(#{red}, #{green}, #{blue}#{alpha_to_string(alpha, options)})"
  end

  defp alpha_to_string(alpha, options) do
    case {alpha, Keyword.get(options, :with_alpha, false)} do
      {@max_percent, false} ->
        ""

      {alpha, _} ->
        decimal =
          (alpha / 100)
          |> Float.round(2)
          |> Float.to_string()

        ", " <> decimal
    end
  end

  @spec parse!(String.t()) :: t()
  def parse!("rgb" <> _ = string) do
    color =
      with :error <- parse_rgb_with_alpha!(string),
           :error <- parse_rgb!(string) do
        raise ArgumentError, "invalid RGB string"
      end

    %Color{color | source: :rgb}
  end

  def parse!("hsl" <> _ = string) do
    {hue, saturation, lightness, maybe_alpha} =
      case Regex.scan(hsl_css_regex(), string) do
        [[_, hue, _, saturation, lightness, _, maybe_alpha]] ->
          {hue, saturation, lightness, maybe_alpha}

        [[_, hue, _, saturation, lightness]] ->
          {hue, saturation, lightness, ""}
      end

    [hue_int, saturation_int, lightness_int] =
      Enum.map([hue, saturation, lightness], &String.to_integer/1)

    alpha = parse_alpha!(maybe_alpha)
    color = hsl!({hue_int, saturation_int, lightness_int}, alpha)
    %Color{color | source: :hsl}
  end

  def parse!("#" <> hex) do
    parse!(hex)
  end

  def parse!(hex) do
    color = rgb_from_hex!(hex)
    %Color{color | source: :hex}
  end

  defp parse_rgb!(string) do
    case Regex.scan(rgb_css_regex(), string) do
      [[_, red, green, blue]] ->
        [red_int, green_int, blue_int] = Enum.map([red, green, blue], &String.to_integer/1)
        rgb!({red_int, green_int, blue_int})
    end
  rescue
    _ -> :error
  end

  defp rgb_css_regex, do: ~r/^rgb\(([0-9]{1,3}), *([0-9]{1,3}), *([0-9]{1,3})\)$/

  defp hsl_css_regex,
    do: ~r/^hsl?\(([0-9]{1,3})(deg)?, *([0-9]{1,3})%?, *([0-9]{1,3})%?(, *(.*))?\)$/

  defp parse_rgb_with_alpha!(string) do
    case Regex.scan(rgba_css_regex(), string) do
      [[_, red, green, blue, maybe_alpha]] ->
        [red_int, green_int, blue_int] = Enum.map([red, green, blue], &String.to_integer/1)
        alpha = parse_alpha!(maybe_alpha)
        rgb!({red_int, green_int, blue_int}, alpha)
    end
  rescue
    _ -> :error
  end

  defp rgba_css_regex, do: ~r/^rgba?\(([0-9]{1,3}), *([0-9]{1,3}), *([0-9]{1,3}), *(.*)\)$/

  defp parse_alpha!(string) do
    Enum.reduce_while(alpha_formats(), @max_percent, fn {key, format}, acc ->
      result =
        format
        |> Regex.scan(string)
        |> decode_format(key)

      case result do
        nil -> {:cont, acc}
        value -> {:halt, value}
      end
    end)
  end

  defp alpha_formats do
    [
      percent: ~r/([0-9]{1,3})%/,
      decimal: ~r/[0-1](\.[0-9]+)?/
    ]
  end

  defp decode_format([[_, percent]], :percent), do: String.to_integer(percent)

  defp decode_format([[decimal | _]], :decimal) do
    decimal = String.to_float(decimal)
    round(decimal * 100)
  end

  defp decode_format(_, _), do: nil

  def range(:hue), do: 1..@max_degree
  def range(:saturation), do: 1..@max_percent
  def range(:lightness), do: 1..@max_percent
  def range(:alpha), do: 1..@max_percent
  def range(color) when color in ~w(red green blue)a, do: 1..@max_hex
end
