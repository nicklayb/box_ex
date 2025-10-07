defmodule Box.Ecto.ChangesetTest do
  use Box.BaseCase

  alias Box.Ecto.Changeset, as: BoxChangeset

  defmodule TestUser do
    use Ecto.Schema

    embedded_schema do
      field(:title, :string)
      field(:slug, :string)
      field(:another_slug, :string)
    end

    def changeset(user \\ %TestUser{}, params), do: Ecto.Changeset.cast(user, params, [:title])
  end

  describe "generate_slug/2" do
    test "generates a slug validating it exists or not" do
      changeset = TestUser.changeset(%{title: "This is a title"})

      assert %Ecto.Changeset{changes: %{slug: "this-is-a-title"}} =
               BoxChangeset.generate_slug(changeset,
                 source: :title,
                 exists?: &exists_in_process?(&1, :slug)
               )

      assert %Ecto.Changeset{changes: %{slug: "this-is-a-title-1"}} =
               BoxChangeset.generate_slug(changeset,
                 source: :title,
                 exists?: &exists_in_process?(&1, :slug)
               )

      assert %Ecto.Changeset{changes: %{another_slug: "this-is-a-title"}} =
               BoxChangeset.generate_slug(changeset,
                 source: :title,
                 field: :another_slug,
                 exists?: &exists_in_process?(&1, :another_slug)
               )

      assert %Ecto.Changeset{changes: %{another_slug: "this+is+a+title"}} =
               BoxChangeset.generate_slug(changeset,
                 source: :title,
                 separator: "+",
                 field: :another_slug,
                 exists?: &exists_in_process?(&1, :another_slug)
               )
    end

    test "doesn't generate a slug if the name didn't change" do
      changeset = TestUser.changeset(%TestUser{title: "Title"}, %{})

      assert %Ecto.Changeset{changes: changes} =
               BoxChangeset.generate_slug(changeset,
                 source: :title,
                 exists?: &exists_in_process?(&1, :slug)
               )

      assert changes == %{}
    end
  end

  describe "change_empty/3" do
    test "adds value only if previous is nil" do
      changeset = TestUser.changeset(%{title: "Title"})

      assert %Ecto.Changeset{errors: [], valid?: true, changes: %{slug: "Slug"}} =
               Box.Ecto.Changeset.change_empty(changeset, :slug, "Slug")

      assert %Ecto.Changeset{
               errors: [{:title, {"expected to be empty, got Title", []}}],
               valid?: false,
               changes: %{title: "Title"}
             } =
               Box.Ecto.Changeset.change_empty(changeset, :title, "New Title")

      assert %Ecto.Changeset{
               errors: [{:title, {"expected to be empty, got Title", []}}],
               valid?: false,
               changes: %{}
             } =
               %TestUser{title: "Title"}
               |> TestUser.changeset(%{})
               |> Box.Ecto.Changeset.change_empty(:title, "New Title")
    end
  end

  defp exists_in_process?(name, field) do
    key = {field, :slugs}
    known_slugs = Process.get(key) || []

    if name in known_slugs do
      true
    else
      Process.put(key, [name | known_slugs])
      false
    end
  end
end
