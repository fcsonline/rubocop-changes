# frozen_string_literal: true

require 'git_diff_parser'
require 'byebug'
require 'rubocop'
require 'json'

require 'rubocop/changes/check'
require 'rubocop/changes/shell'

module Rubocop
  module Changes
    class UnknownForkPointError < StandardError; end

    class Checker
      def run
        raise UnknownForkPointError if fork_point.empty?

        # TODO: Let users choose the formatter
        formatter = RuboCop::Formatter::SimpleTextFormatter.new($stdout)

        formatter.started('')

        print_offenses(formatter)

        formatter.finished(ruby_changed_files)

        checks.map(&:offenses).flatten
      end

      private

      def fork_point
        @fork_point ||= Shell.run('git merge-base HEAD origin/master')
      end

      def diff
        Shell.run("git diff #{fork_point}")
      end

      def patches
        @patches ||= GitDiffParser.parse(diff)
      end

      def changed_files
        patches.map(&:file)
      end

      def ruby_changed_files
        changed_files.select { |changed_file| changed_file =~ /.rb$/ }
      end

      def rubocop
        Shell.run("bundle exec rubocop -f j #{ruby_changed_files.join(' ')}")
      end

      def rubocop_json
        @rubocop_json ||= JSON.parse(rubocop, object_class: OpenStruct)
      end

      def checks
        @checks ||= ruby_changed_files.map do |file|
          analysis = rubocop_json.files.find { |item| item.path == file }
          patch = patches.find { |item| item.file == file }

          next unless analysis

          Check.new(analysis, patch)
        end.compact
      end

      def offended_lines
        checks.map(&:offended_lines).flatten.compact
      end

      def total_offenses
        checks.map { |check| check.offended_lines.size }.inject(0, :+)
      end

      def print_offenses(formatter)
        checks.each do |check|
          print_offenses_for_check(formatter, check)
        end
      end

      def print_offenses_for_check(formatter, check)
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
    end
  end
end
