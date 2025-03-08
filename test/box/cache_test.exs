defmodule Box.CacheTest do
  use Box.BaseCase, async: false

  require Assertions

  alias Box.Cache

  @name TestCache

  setup do
    start_supervised!({Box.Cache.Server, name: @name})
    :ok
  end

  describe "all/1" do
    test "gets all cached values" do
      assert [] == Cache.all(@name)
      insert_sync(@name, {:key, :first})
      Assertions.assert_lists_equal([{:key, :first, [expiration: :never]}], Cache.all(@name))

      insert_sync(@name, {:key, :overrides})
      Assertions.assert_lists_equal([{:key, :overrides, [expiration: :never]}], Cache.all(@name))

      insert_sync(@name, {:another_key, :value})

      Assertions.assert_lists_equal(
        [
          {:key, :overrides, [expiration: :never]},
          {:another_key, :value, [expiration: :never]}
        ],
        Cache.all(@name)
      )
    end
  end

  describe "get/2" do
    test "gets value in cache" do
      assert {:error, :not_found} == Cache.get(@name, :my_key)
      Cache.insert(@name, {:my_key, :value})

      wait_until(fn ->
        assert {:ok, :value} == Cache.get(@name, :my_key)
      end)
    end

    test "gets value in cache and expires after ttl" do
      assert {:error, :not_found} == Cache.get(@name, :my_key)
      Cache.insert(@name, {:my_key, :value}, ttl: 100)

      wait_until(fn ->
        assert {:ok, :value} == Cache.get(@name, :my_key)
      end)

      wait_until(fn ->
        assert {:error, :not_found} == Cache.get(@name, :my_key)
      end)
    end

    test "gets value in cache with tuple key" do
      assert {:error, :not_found} == Cache.get(@name, :my_key)
      Cache.insert(@name, {{:some_key, 2112}, :value})

      wait_until(fn ->
        assert {:ok, :value} == Cache.get(@name, {:some_key, 2112})
      end)
    end
  end

  describe "memoize/3" do
    test "memoizes a function" do
      function = fn ->
        Box.Support.Process.update(:invoked, 1, &(&1 + 1))
        2112
      end

      key = :some_key

      assert 2112 == Cache.memoize(@name, key, function)

      wait_until(fn ->
        assert {:ok, 2112} == Cache.get(@name, key)
      end)

      assert 2112 == Cache.memoize(@name, key, function)
      assert 2112 == Cache.memoize(@name, key, function)
      assert 1 == Process.get(:invoked)
    end

    test "memoizes a function with a ttl" do
      function = fn ->
        Box.Support.Process.update(:invoked, 1, &(&1 + 1))
        2112
      end

      key = :some_key

      assert 2112 == Cache.memoize(@name, key, [ttl: 500], function)

      wait_until(fn ->
        assert {:ok, 2112} == Cache.get(@name, key)
      end)

      assert 2112 == Cache.memoize(@name, key, function)
      assert 2112 == Cache.memoize(@name, key, function)
      assert 1 == Process.get(:invoked)

      wait_until(fn ->
        assert {:error, :not_found} == Cache.get(@name, key)
      end)

      assert 2112 == Cache.memoize(@name, key, function)

      wait_until(fn ->
        assert 2 == Process.get(:invoked)
      end)
    end

    test "memoizes if cache matches" do
      function = fn ->
        Box.Support.Process.update(:invoked, 1, &(&1 + 1))
        {:ok, 2112}
      end

      key = :some_key

      assert {:ok, 2112} ==
               Cache.memoize(@name, key, [cache_match: &Box.Result.succeeded?/1], function)

      wait_until(fn ->
        assert {:ok, {:ok, 2112}} == Cache.get(@name, key)
      end)

      assert {:ok, 2112} ==
               Cache.memoize(@name, key, [cache_match: &Box.Result.succeeded?/1], function)

      assert {:ok, 2112} ==
               Cache.memoize(@name, key, [cache_match: &Box.Result.succeeded?/1], function)

      assert 1 == Process.get(:invoked)
    end

    test "does not memoize if cache doesn't match" do
      function = fn ->
        Box.Support.Process.update(:invoked, 1, &(&1 + 1))
        {:error, :not_found}
      end

      key = :some_key

      assert {:error, :not_found} ==
               Cache.memoize(@name, key, [cache_match: &Box.Result.succeeded?/1], function)

      assert {:error, :not_found} ==
               Cache.memoize(@name, key, [cache_match: &Box.Result.succeeded?/1], function)

      assert {:error, :not_found} ==
               Cache.memoize(@name, key, [cache_match: &Box.Result.succeeded?/1], function)

      assert 3 == Process.get(:invoked)
    end
  end

  defp insert_sync(cache, {key, value} = record, options \\ []) do
    Cache.insert(cache, record, options)

    wait_until(fn ->
      assert {:ok, ^value} = Cache.get(cache, key)
    end)
  end
end
