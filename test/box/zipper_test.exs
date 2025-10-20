defmodule Box.ZipperTest do
  use Box.BaseCase

  alias Box.Zipper

  describe "new/1" do
    test "create a zipper" do
      assert %Zipper{
        previous: [],
        current: :a,
        next: [:b, :c, :d]
      }

      assert_raise(ArgumentError, fn -> Zipper.new([]) end)
    end
  end

  describe "next/1" do
    test "pick next item and circle back once finished" do
      initial_zipper = Zipper.new([1, 2, 3])
      assert %Zipper{previous: [], current: 1, next: [2, 3]} = initial_zipper

      assert {:cont, %Zipper{previous: [1], current: 2, next: [3]} = zipper} =
               Zipper.next(initial_zipper)

      assert {:cont, %Zipper{previous: [2, 1], current: 3, next: []} = zipper} =
               Zipper.next(zipper)

      assert {:reset, ^initial_zipper} =
               Zipper.next(zipper)

      assert {:cont, %Zipper{}} =
               initial_zipper
               |> Zipper.next()
               |> Zipper.next()
    end
  end

  describe "previous/1" do
    test "pick next item and circle back once finished" do
      initial_zipper = Zipper.new([1, 2, 3])
      assert %Zipper{previous: [], current: 1, next: [2, 3]} = initial_zipper

      assert {:cont, %Zipper{previous: [2, 1], current: 3, next: []} = zipper} =
               Zipper.previous(initial_zipper)

      assert {:cont, %Zipper{previous: [1], current: 2, next: [3]} = zipper} =
               Zipper.previous(zipper)

      assert {:reset, ^initial_zipper} =
               Zipper.previous(zipper)

      assert {:cont, %Zipper{}} =
               initial_zipper
               |> Zipper.previous()
               |> Zipper.previous()
    end
  end

  describe "reset/1" do
    test "resets a zipper" do
      initial_zipper = Zipper.new([1, 2, 3])

      assert initial_zipper == Zipper.reset(initial_zipper)

      assert {:cont, next_zipper} = Zipper.next(initial_zipper)

      refute next_zipper == initial_zipper

      assert initial_zipper == Zipper.reset(next_zipper)
    end
  end

  describe "current/1" do
    test "gets current element" do
      initial_zipper = Zipper.new([1, 2, 3])
      assert 1 == Zipper.current(initial_zipper)

      assert {:cont, zipper} = Zipper.next(initial_zipper)
      assert 2 == Zipper.current(zipper)
    end
  end

  describe "to_ordered_list/1" do
    test "returns a list with identified current" do
      initial_zipper = Zipper.new([1, 2, 3])
      assert [{:current, 1}, 2, 3] = Zipper.to_ordered_list(initial_zipper)
      {:cont, zipper} = Zipper.next(initial_zipper)
      assert [1, {:current, 2}, 3] = Zipper.to_ordered_list(zipper)
      {:cont, zipper} = Zipper.next(zipper)
      assert [1, 2, {:current, 3}] = Zipper.to_ordered_list(zipper)
    end
  end
end
