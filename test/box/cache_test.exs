defmodule Box.CacheTest do
  use Box.BaseCase, async: false

  alias Box.Cache

  @name TestCache

  setup do
    start_supervised!({Box.Cache.Server, name: @name})
    :ok
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
  end
end
