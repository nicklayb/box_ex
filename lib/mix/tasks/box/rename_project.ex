defmodule Mix.Tasks.Box.RenameProject do
  @moduledoc """
  Renames a project to a new name. It expects the following arguments:

  - `from`: The source name it needs to be renamed from
  - `to`: The destination name

  And optionally supports the following

  - `folder`: The folder to do the renaming.
  - `dry_run`: Doesn't perform any renaming. Might not work if folders are renamed

  **Note**: Both needs to be snake case names. If renaming the modules from
  "MyApp" to "TheFallenDragons" then the task should be used as 

  ```sh
  mix box.rename_project --from my_app --to the_fallen_dragon
  ```
  """
  @shortdoc "Renames a project"

  use Mix.Task

  require Logger

  @ingored_path [
    ~r/\/?deps/,
    ~r/\/?_build/,
    ~r/\/?.git/,
    ~r/\/?.elixir_ls/
  ]

  @options [
    strict: [
      from: :string,
      to: :string,
      dry_run: :boolean,
      folder: :string
    ]
  ]

  @impl Mix.Task
  def run(args) do
    {options, _, _} = OptionParser.parse(args, @options)
    {from, options} = Keyword.pop!(options, :from)
    {to, options} = Keyword.pop!(options, :to)

    with [{key, option} | _] <- Enum.reject([from: from, to: to], &snake_cased?/1) do
      raise "Expected snake case only, got #{option} for option #{key}"
    end

    case run(from, to, options) do
      [] -> Logger.info("[#{inspect(__MODULE__)}] no files replaced")
      files -> Logger.info("[#{inspect(__MODULE__)}] #{length(files)} replaced")
    end
  end

  defp snake_cased?({_, value}), do: snake_cased?(value)

  defp snake_cased?(value) do
    Regex.match?(~r/^[a-z][a-z_0-9]*$/, value)
  end

  @root_folder "./"
  defp run(from, to, options) do
    folder =
      options
      |> Keyword.get(:folder, @root_folder)
      |> Path.expand()

    Box.File.walk_folder(folder, [], &folder_walker(folder, {from, to}, &1, &2, options))
  end

  defp folder_walker(_, {from, to}, {:file, file}, acc, options) do
    content_updated? = replace_content(file, {from, to}, options)
    new_name = String.replace(file, from, to)
    name_updated? = rename_file(file, new_name, options)

    if name_updated? or content_updated? do
      [new_name | acc]
    else
      acc
    end
  end

  defp folder_walker(base_folder, {from, to}, {:dir, dir}, _, options) do
    if folder_ingored?(base_folder, dir) do
      :discard
    else
      new_name = String.replace(dir, from, to)

      name_updated? = rename_file(dir, new_name, options)

      if name_updated? do
        {:rename, new_name}
      else
        :continue
      end
    end
  end

  defp folder_ingored?(base_folder, folder) do
    only_folder = String.replace(folder, base_folder, "")

    Enum.any?(@ingored_path, fn path ->
      Regex.match?(path, only_folder)
    end)
  end

  defp rename_file(name, name, _), do: false

  defp rename_file(old_name, new_name, options) do
    if dry_run?(options) do
      Logger.info("[#{inspect(__MODULE__)}] [dryrun] #{old_name} -> #{new_name}")
    else
      :ok = File.rename(old_name, new_name)
      Logger.info("[#{inspect(__MODULE__)}] #{old_name} -> #{new_name}")
    end

    true
  end

  defp replace_content(file, {from, to}, options) do
    patterns = content_patterns(from, to)

    content = File.read!(file)

    new_content =
      Enum.reduce(patterns, content, fn {old, new}, acc ->
        String.replace(acc, old, new)
      end)

    write_content(file, content, new_content, options)
  end

  defp write_content(_file, content, content, _options), do: false

  defp write_content(file, _from, new_content, options) do
    if dry_run?(options) do
      Logger.info("[#{inspect(__MODULE__)}] [dryrun] #{file} updated")
      false
    else
      :ok = File.write!(file, new_content)
      Logger.info("[#{inspect(__MODULE__)}] #{file} updated")
      true
    end
  end

  defp content_patterns(from, to) do
    camelized_from = Macro.camelize(from)
    camelized_to = Macro.camelize(to)

    %{
      ":#{from}_web" => ":#{to}_web",
      ":#{from}" => ":#{to}",
      from => to,
      (camelized_from <> "Web") => camelized_to <> "Web",
      camelized_from => camelized_to
    }
  end

  defp dry_run?(options) do
    Keyword.get(options, :dry_run, false)
  end
end
