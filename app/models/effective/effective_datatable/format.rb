module Effective
  module EffectiveDatatable
    module Format
      BLANK = ''.freeze
      NONVISIBLE = '...'.freeze
      SPACER = 'EFFECTIVEDATATABLESSPACER'.freeze
      SPACER_TEMPLATE = '/effective/datatables/spacer_template'.freeze

      private

      def format(collection)
        # We want to use the render :collection for each column that renders partials
        rendered = {}

        columns.each do |name, opts|
          next unless state[:visible][name]

          if opts[:partial]
            locals = { datatable: self, column: columns[name] }.merge(resource_col_locals(opts))

            rendered[name] = (view.render(
              partial: opts[:partial],
              as: (opts[:partial_as] || :resource),
              collection: collection.map { |row| row[opts[:index]] },
              formats: :html,
              locals: locals,
              spacer_template: SPACER_TEMPLATE
            ) || '').split(SPACER)
          elsif opts[:as] == :actions # This is actions_col and actions_col do .. end, but not actions_col partial: 'something'
            resources = collection.map { |row| row[opts[:index]] }
            locals = { datatable: self, column: opts, spacer_template: SPACER_TEMPLATE }
            atts = { actions: actions_col_actions(opts), effective_resource: resource, locals: locals, partial: opts[:actions_partial] }.merge(opts[:actions])

            rendered[name] = (view.render_resource_actions(resources, atts, &opts[:format]) || '').split(SPACER)
          end

        end

        collection.each_with_index do |row, row_index|
          columns.each do |name, opts|
            index = opts[:index]
            value = row[index]

            row[index] = (
              if state[:visible][name] == false
                NONVISIBLE
              elsif opts[:as] == :actions
                rendered[name][row_index]
              elsif opts[:format] && rendered.key?(name)
                dsl_tool.instance_exec(value, row, rendered[name][row_index], &opts[:format])
              elsif opts[:format]
                dsl_tool.instance_exec(value, row, &opts[:format])
              elsif opts[:partial]
                rendered[name][row_index]
              else
                format_column(value, opts)
              end
            )
          end
        end
      end

      def format_column(value, column)
        return if value.nil? || (column[:resource] && value.blank?)

        unless column[:as] == :email
          return value if value.kind_of?(String)
        end

        case column[:as]
        when :actions
          atts = { actions: actions_col_actions(column), effective_resource: resource, partial: column[:actions_partial] }.merge(column[:actions])
          (view.render_resource_actions(value, atts) || '')
        when :boolean
          case value
          when true   ; 'Yes'
          when false  ; 'No'
          end
        when :currency
          view.number_to_currency(value)
        when :date
          (value.strftime('%F') rescue BLANK)
        when :datetime
          (value.strftime('%F %H:%M') rescue BLANK)
        when :decimal
          value
        when :duration
          view.number_to_duration(value)
        when :effective_addresses
          value.to_html
        when :effective_obfuscation
          value
        when :effective_roles
          value.join(', ')
        when :email
          view.mail_to(value)
        when :integer
          value
        when :percentage
          case value
          when Integer    ; "#{value}%"
          when Numeric    ; view.number_to_percentage(value * 100, precision: 2)
          end
        when :price
          case value
          when Integer    ; view.number_to_currency(value / 100.0) # an Integer representing the number of cents
          when Numeric    ; view.number_to_currency(value)
          end
        when :time
          (value.strftime('%H:%M') rescue BLANK)
        else
          value.to_s
        end
      end

      # Takes all default resource actions
      # Applies data-remote to anything that's data-method post or delete
      def actions_col_actions(column)
        resource.resource_actions
      end

      def resource_col_locals(opts)
        return {} unless (resource = opts[:resource]).present?

        locals = { name: opts[:name], effective_resource: resource, show_action: false, edit_action: false }

        case opts[:action]
        when :edit
          locals[:edit_action] = (resource.routes[:edit] && EffectiveDatatables.authorized?(view.controller, :edit, resource.klass))
        when :show
          locals[:show_action] = (resource.routes[:show] && EffectiveDatatables.authorized?(view.controller, :show, resource.klass))
        when false
          # Nothing
        else
          # Fallback to defaults - check edit then show
          if resource.routes[:edit] && EffectiveDatatables.authorized?(view.controller, :edit, resource.klass)
            locals[:edit_action] = true
          elsif resource.routes[:show] && EffectiveDatatables.authorized?(view.controller, :show, resource.klass)
            locals[:show_action] = true
          end
        end

        locals
      end

    end # / Rendering
  end
end
