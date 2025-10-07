defmodule Box.Ecto.SchemaTest do
  use Box.BaseCase

  require Assertions

  defmodule TestUser do
    use Ecto.Schema
    import Box.Ecto.Schema

    embedded_schema do
      flag(:disabled)
      flag(:activate, key: :is_activated_on)
    end

    def changeset(user \\ %TestUser{}, params), do: Ecto.Changeset.cast(user, params, [:title])
  end

  describe "flag/2" do
    test "fields are correctly defined" do
      assert %TestUser{disabled: _, disabled_at: _, activate: _, is_activated_on: _} = %TestUser{}

      assert Assertions.assert_lists_equal(
               [:id, :disabled_at, :is_activated_on],
               TestUser.__schema__(:fields)
             )

      assert Assertions.assert_lists_equal(
               [:disabled, :activate],
               TestUser.__schema__(:virtual_fields)
             )
    end
  end
end
