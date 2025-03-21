defmodule Box.EnumTest do
  use Box.BaseCase
  doctest Box.Enum

  describe "replace/3" do
    test "replace value in enumerable" do
      assert [1, :two, 3, 4] = Box.Enum.replace([1, 2, 3, 4], &(&1 == 2), :two)
    end
  end

  describe "key_by/2" do
    test "keys an enumerable by a given function" do
      assert %{one: 1, two: 2, three: 3} =
               Box.Enum.key_by([1, 2, 3], fn
                 1 -> :one
                 2 -> :two
                 3 -> :three
               end)
    end
  end

  describe "field/2" do
    test "gets field of inner map" do
      assert [1, 2, nil, 3] = Box.Enum.field([%{value: 1}, %{value: 2}, %{}, %{value: 3}], :value)
    end
  end
end
