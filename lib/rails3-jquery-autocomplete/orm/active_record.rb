module Rails3JQueryAutocomplete
  module Orm
    module ActiveRecord
      def get_autocomplete_order(method, options, model=nil)
        order = options[:order]

        table_prefix = model ? "#{model.table_name}." : ""
        order || "#{table_prefix}#{method} ASC"
      end

      def get_autocomplete_items(parameters)
        model   = parameters[:model]
        term    = parameters[:term]
        method  = parameters[:method]
        options = parameters[:options]
        scopes  = Array(options[:scopes])
        where   = options[:where]
        limit   = get_autocomplete_limit(options)
        order   = get_autocomplete_order(method, options, model)


        items = model.scoped

        scopes.each { |scope| items = items.send(scope) } unless scopes.empty?

        items = items.select(get_autocomplete_select_clause(model, method, options)) unless options[:full_model]
        items = if options[:custom_search]
          eval("items.#{options[:custom_search]}")
        else
          items.where(get_autocomplete_where_clause(model, term, method, options))
        end.limit(limit).order(order)
        items = items.where(where) unless where.blank?

        items
      end

      def get_autocomplete_select_clause(model, method, options)
        table_name = model.table_name
        (["#{table_name}.#{model.primary_key}", "#{table_name}.#{method}"] + (options[:extra_data].blank? ? [] : options[:extra_data]))
      end

      def get_autocomplete_where_clause(model, term, method, options)
        table_name = model.table_name
        is_full_search = options[:full]
        like_clause = (postgres? ? 'ILIKE' : 'LIKE')
        ["LOWER(#{table_name}.#{method}) #{like_clause} ?", "#{(is_full_search ? '%' : '')}#{term.downcase}%"]
      end

      def postgres?
        defined?(PGconn)
      end
    end
  end
end
