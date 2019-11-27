require 'git_diff_parser'
require 'byebug'
require 'rubocop'
require 'json'

require 'rubocop/changes/check'

module Rubocop
  module Changes
    class UnknownForkPointError < StandardError; end

    class Checker
      def run
        raise UnknownForkPointError if fork_point.empty?

        # TODO: Let users choose the formatter
        formatter = RuboCop::Formatter::SimpleTextFormatter.new($stdout)

        formatter.started('')

        checks.each do |check|
          offenses = check.offenses.map do |offense|
            RuboCop::Cop::Offense.new(
              offense.severity,
              offense.location,
              offense.message,
              offense.cop_name
            )
          end

          formatter.file_finished(check.path, offenses)
        end

        formatter.finished(ruby_changed_files)

        checks.map(&:offenses).flatten
      end

      private

      def diff
        `git diff $(git merge-base HEAD origin/master)`
      end

      def fork_point
        `git merge-base HEAD origin/master`.strip
      end

      def changed_files
        `git diff --name-only #{fork_point}..`.split("\n")
      end

      def ruby_changed_files
        changed_files.select { |changed_file| changed_file =~ /.rb$/ }
      end

      def offended_lines
        checks.map(&:offended_lines).flatten.compact
      end

      def total_offenses
        checks.map { |check| check.offended_lines.size }.inject(0, :+)
      end

      def checks
        @checks ||= ruby_changed_files.map do |file|
          analysis = rubocop_json.files.find { |item| item.path == file }
          patch = patches.find { |item| item.file == file }

          Check.new(analysis, patch)
        end
      end

      def patches
        @patches ||= GitDiffParser.parse(diff)
      end

      def rubocop
        `bundle exec rubocop -f j #{changed_files.join(' ')}`.strip
      end

      def rubocop_json
        @rubocop_json ||= JSON.parse(rubocop, object_class: OpenStruct)
      end
    end
  end
end
