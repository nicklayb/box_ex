if Code.ensure_loaded?(Ecto.Repo) do
  defmodule Box.Ecto.Pagination.Page do
    alias Box.Ecto.Pagination.Page

    defstruct [:results, :query, :has_next_page, :limit, :offset, :sort_by, :index]

    @type result :: any()
    @type query :: Ecto.Queryable.t()

    @type sort_by :: function() | {:asc | :desc, atom()} | atom()

    @type t :: %Page{
            results: [result()],
            query: query(),
            has_next_page: boolean(),
            limit: non_neg_integer(),
            offset: non_neg_integer(),
            sort_by: sort_by()
          }

    @doc """
    Creates a new page from another page and some results
    """
    @spec new([result()], t()) :: t()
    def new(results, %Page{query: query, sort_by: sort_by, limit: limit, offset: offset}) do
      new(results, query, limit, offset, sort_by)
    end

    @doc """
    Creates a new page
    """
    @spec new([result()], query(), non_neg_integer(), non_neg_integer(), sort_by()) :: t()
    def new(results, query, limit, offset, sort_by) do
      has_next_page = Enum.count(results) > limit

      %Page{
        results: Enum.take(results, limit),
        query: query,
        has_next_page: has_next_page,
        limit: limit,
        offset: offset,
        sort_by: sort_by
      }
    end

    @doc """
    Merges two pages together using a merge function.
    """
    @spec merge(t(), t(), ([result()], [result()] -> any())) :: t()
    def merge(
          %Page{results: previous_results},
          %Page{} = right,
          merge_function \\ &Kernel.++/2
        ) do
      map_results(right, fn new_results -> merge_function.(previous_results, new_results) end)
    end

    @doc """
    Maps results over
    """
    @spec map_results(t(), ([any()] -> [any()])) :: t()
    def map_results(%Page{results: results} = page, function) do
      %Page{page | results: function.(results)}
    end

    @doc """
    Maps invdividual result over
    """
    @spec map_every_results(t(), (any() -> any())) :: t()
    def map_every_results(%Page{} = page, function) do
      map_results(page, &Enum.map(&1, function))
    end
  end
end
