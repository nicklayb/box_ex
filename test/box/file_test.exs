defmodule Box.FileTest do
  use Box.BaseCase

  describe "walk_folder/3" do
    test "walks folder supporting discard and renaming" do
      assert %{
               alpha: true,
               binary_flags: true,
               binary_flags_type: true,
               changeset_test: true
             } ==
               Box.File.walk_folder("./", %{}, fn
                 {:dir, dir}, acc ->
                   cond do
                     # Will look into Ecto tests folder
                     String.ends_with?(dir, "test/box/ecto") ->
                       :continue

                     # Will avoid cache and look into generator instead
                     String.ends_with?(dir, "test/box/cache") ->
                       {:rename, String.replace(dir, "box/cache", "box/generator")}

                     # Will look into binary flags, mutating the acc
                     String.ends_with?(dir, "lib/box/binary_flags") ->
                       {:update, Map.put(acc, :binary_flags, true)}

                     # Would look into the folder and mutate the acc but it doesn't exist
                     String.ends_with?(dir, "lib/something_that_doesnt_exist") ->
                       {:update, Map.put(acc, :not_exists, true)}

                     String.ends_with?(dir, "test") ->
                       :continue

                     String.ends_with?(dir, "test/box") ->
                       :continue

                     String.ends_with?(dir, "test/box/cache") ->
                       :continue

                     String.ends_with?(dir, "test/box/ecto") ->
                       :continue

                     String.ends_with?(dir, "lib") ->
                       :continue

                     String.ends_with?(dir, "lib/box") ->
                       :continue

                     String.ends_with?(dir, "lib/box/binary_flags") ->
                       :continue

                     String.ends_with?(dir, "test") ->
                       :continue

                     # Discard everything else
                     true ->
                       :discard
                   end

                 {:file, file}, acc ->
                   cond do
                     # Accumulate when alphanumerical_test is found (should be from the :rename above)
                     String.ends_with?(file, "alphanumerical_test.exs") ->
                       Map.put(acc, :alpha, true)

                     # Accumulate when file_server_test is found (shouldn't be since we're deferring to generator)
                     String.ends_with?(file, "file_server_test.exs") ->
                       Map.put(acc, :file_server, true)

                     # Accumulate when changeset_test is found (should be from the :continue above)
                     String.ends_with?(file, "changeset_test.exs") ->
                       Map.put(acc, :changeset_test, true)

                     # Accumulate when ecto_type is found (should be from the :update above)
                     String.ends_with?(file, "binary_flags/ecto_type.ex") ->
                       Map.put(acc, :binary_flags_type, true)

                     true ->
                       acc
                   end
               end)
    end
  end
end

