defmodule Box.File do
  @type directory_walker :: ({:dir, Path.t()}, any() ->
                               :discard | :continue | {:rename, Path.t()} | {:update, any()})
  @type file_walker :: ({:file, Path.t()}, any() -> any())
  @type walker_function :: directory_walker() | file_walker()

  @doc """
  Walks folder structure. The folder is expanded if that's not already the case
  so expect to walker to receive full path.
  """
  @spec walk_folder(Path.t(), any(), walker_function()) :: any()
  def walk_folder("/" <> _ = folder, accumulator, function) do
    folder
    |> File.ls!()
    |> Enum.reduce(accumulator, fn file, current_accumulator ->
      full_path = Path.join(folder, file)

      if File.dir?(full_path) do
        accumulate_folder(full_path, current_accumulator, function)
      else
        function.({:file, full_path}, current_accumulator)
      end
    end)
  end

  def walk_folder(folder, accumulator, function) do
    folder
    |> Path.expand()
    |> walk_folder(accumulator, function)
  end

  defp accumulate_folder(folder, acc, function) do
    case function.({:dir, folder}, acc) do
      {:rename, new_name} ->
        folder
        |> String.replace(folder, new_name)
        |> walk_folder(acc, function)

      :discard ->
        acc

      :continue ->
        walk_folder(folder, acc, function)

      {:update, new_acc} ->
        walk_folder(folder, new_acc, function)
    end
  end
end
