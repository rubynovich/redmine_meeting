require_dependency 'prawn/table/cell'

module MeetingPlugin
  module PrawnTableCellPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :min_width, :patch
        alias_method_chain :max_width, :patch
#        alias_method_chain :height, :patch
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def min_width_with_patch
        min_width_ignoring_span
      end

      def max_width_with_patch
        min_width_ignoring_span
      end

      def height_with_patch
        return height_ignoring_span if @colspan == 1 && @rowspan == 1

        # We're in a span group; get the maximum height per row (including the
        # master cell) and sum each row.
        row_heights = Hash.new(0)
        dummy_cells.each do |cell|
          row_heights[cell.row] = [row_heights[cell.row], cell.height].max
        end
        row_heights[row] = [row_heights[row], height_ignoring_span].max
        row_heights.values.inject(0, &:+)
      end
    end
  end
end
