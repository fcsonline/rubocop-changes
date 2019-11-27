# frozen_string_literal: true

module Rubocop
  module Changes
    class Check
      def initialize(analysis, patch)
        @analysis = analysis
        @patch = patch
      end

      def offenses
        analysis.offenses.select do |offense|
          line_numbers.include?(line(offense))
        end
      end

      def path
        analysis.path
      end

      private

      attr_reader :analysis, :patch

      def line_numbers
        lines_from_diff & lines_from_rubocop
      end

      def lines_from_diff
        patch.changed_line_numbers
      end

      def lines_from_rubocop
        analysis
          .offenses
          .map(&method(:line))
          .uniq
      end

      def line(offense)
        offense.location.line
      end
    end
  end
end
