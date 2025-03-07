defmodule Box.Cache.FileServer do
  use Agent

  @callback decode(String.t(), Keyword.t()) :: {:ok, [{String.t(), any()}]} | {:error, any()}

  def start_link(args) do
    name = Keyword.fetch!(args, :name)
    file = Keyword.fetch!(args, :file)
    decoder = Keyword.fetch!(args, :decoder)

    if not File.exists?(file),
      do:
        raise("""
        File #{file} was provided to be cached but it does not exist
        """)

    Agent.start_link(fn -> load_file_in_table(name, file, decoder) end, name: name)
  end

  defp load_file_in_table(name, file, {decoder, decoder_options}) do
    with {:ok, content} <- File.read(file),
         {:ok, records} <- decoder.decode(content, decoder_options) do
      records_with_options = Enum.map(records, fn {key, value} -> {key, value, []} end)
      :ets.new(name, [:protected, :named_table, :set])

      :ets.insert(name, records_with_options)
    end
  end

  defp load_file_in_table(name, file, decoder), do: load_file_in_table(name, file, {decoder, []})
end
