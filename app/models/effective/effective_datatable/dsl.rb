module Effective
  module EffectiveDatatable
    module Dsl

      def bulk_actions(&block)
        define_method('initialize_bulk_actions') { dsl_tool.instance_exec(&block) }
      end

      def charts(&block)
        define_method('initialize_charts') { dsl_tool.instance_exec(&block) }
      end

      def collection(&block)
        define_method('initialize_collection') { self._collection = dsl_tool.instance_exec(&block) }
      end

      def datatable(&block)
        define_method('initialize_datatable') do
          dsl_tool.in_datatables_do_block = true
          dsl_tool.instance_exec(&block)
          dsl_tool.in_datatables_do_block = false
        end
      end

      def filters(&block)
        define_method('initialize_filters') { dsl_tool.instance_exec(&block) }
      end

    end
  end
end
