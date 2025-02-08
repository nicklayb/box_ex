if Code.ensure_loaded?(Ecto.Repo) do
  defmodule Box.Ecto.RepoHelpers do
    defmacro __using__(options) do
      quote do
        require Ecto.Query

        alias Box.Ecto.Pagination.Page

        def first(query) do
          query
          |> Ecto.Query.limit(1)
          |> one()
        end

        def first_id(query) do
          first_field(query, :id)
        end

        def first_field(query, field) do
          query
          |> Ecto.Query.select(^field)
          |> first()
        end

        def fetch(query) do
          query
          |> one()
          |> to_result()
        end

        def fetch(query, id) do
          query
          |> get(id)
          |> to_result()
        end

        defp to_result(result) do
          Box.Result.from_nil(result, :not_found)
        end

        @default_limit Keyword.get(unquote(options), :page_default_limt, 25)
        @default_offset 0
        def paginate(queryable, params \\ %{}) do
          limit = Map.get(params, :limit, @default_limit)
          offset = Map.get(params, :offset, @default_offset)
          sort_by = Map.get(params, :sort_by, :id)

          queryable
          |> Ecto.Query.subquery()
          |> order_paginated_query(sort_by)
          |> Ecto.Query.limit(^(limit + 1))
          |> Ecto.Query.offset(^offset)
          |> all()
          |> Page.new(queryable, limit, offset, sort_by)
        end

        defp order_paginated_query(query, order_by) when is_function(order_by, 1) do
          order_by.(query)
        end

        defp order_paginated_query(query, order_by) do
          Ecto.Query.order_by(query, ^order_by)
        end

        def next(%Page{query: query, limit: limit, offset: offset, sort_by: sort_by}) do
          paginate(query, %{offset: offset + limit, limit: limit, sort_by: sort_by})
        end

        def map_paginated_results(%Page{results: results} = page, function) do
          %Page{page | results: function.(results)}
        end
      end
    end
  end
end
