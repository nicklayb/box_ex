defmodule Box.Color do
  @full_alpha 100
  alias Box.Color

  defstruct [:format, :value, alpha: @full_alpha]

  @max_hex 255
  @max_percent 100
  @max_degree 359
  defguard is_hex(value) when value >= 0 and value <= @max_hex
  defguard is_percent(value) when value >= 0 and value <= @max_percent
  defguard is_degree(value) when value >= 0 and value <= @max_degree

  def hsl!({hue, saturation, lightness}, alpha \\ @full_alpha)
      when is_degree(hue) and is_percent(saturation) and is_percent(lightness) do
    %Color{format: :hsl, value: {hue, saturation, lightness}, alpha: alpha}
  end

  def rgb!({red, green, blue}, alpha \\ @full_alpha)
      when is_hex(red) and is_hex(green) and is_hex(blue) do
    %Color{format: :rgb, value: {red, green, blue}, alpha: alpha}
  end

  def rgb_from_hex!(hex, alpha \\ @full_alpha) do
    <<red::4, green::4, blue::4>> = Base.decode16!(hex)
    rgb!({red, green, blue}, alpha)
  end
end
