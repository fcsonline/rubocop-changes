# frozen_string_literal: true

require 'git_diff_parser'
require 'rubocop'
require 'json'

require 'rubocop/changes/check'
require 'rubocop/changes/shell'

module Rubocop
  module Changes
    class UnknownFormat < StandardError; end
    class UnknownBaseBranchError < StandardError; end
    class UnknownForkPointError < StandardError; end

    class Checker
      def initialize(format:, quiet:, commit:, auto_correct:, base_branch:)
        @format = format
        @quiet = quiet
        @commit = commit
        @auto_correct = auto_correct
        @base_branch = base_branch
      end

      def run
        raise UnknownBaseBranchError if base_branch.empty?
        raise UnknownForkPointError if fork_point.empty?
        raise UnknownFormat if formatter_klass.nil?

        print_offenses! unless quiet

        checks.map(&:offenses).flatten
      end

      private

      attr_reader :format, :quiet, :commit, :auto_correct, :base_branch

      def path_prefix
        return @path_prefix if defined?(@path_prefix)
        @path_prefix = local_git_root_path && Dir.pwd.gsub(local_git_root_path, '')[1..-1]
      end

      def local_git_root_path
        @local_git_root_path ||= Shell.run("git rev-parse --show-toplevel")
      end

      def fork_point
        @fork_point ||= Shell.run(command)
      end

      def command
        return "git merge-base HEAD origin/#{base_branch}" unless commit

        "git log -n 1 --pretty=format:\"%h\" #{commit}"
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
        changed_files.select { |changed_file| changed_file =~ /\.rb$/ }
      end

      def ruby_changed_files_from_pwd
        ruby_changed_files.map do |path|
          if path_prefix
            path.gsub(/^#{path_prefix}\//, '')
          else
            path
          end
        end
      end

      def rubocop
        shell_command = [
          'rubocop',
          exclussion_modifier,
          formatter_modifier,
          auto_correct_modifier
        ].compact.join(' ')

        Shell.run(shell_command)
      end

      def exclussion_modifier
        '--force-exclusion'
      end

      def formatter_modifier
        "-f j #{ruby_changed_files_from_pwd.join(' ')}"
      end

      def auto_correct_modifier
        '-A' if @auto_correct
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

      def print_offenses!
        formatter.started(checks)

        checks.each do |check|
          print_offenses_for_check(check)
        end

        formatter.finished(ruby_changed_files)
      end

      def formatter
        @formatter ||= formatter_klass.new($stdout)
      end

      def formatter_klass
        return formatters[format] unless formatters[format].is_a? String

        Kernel.const_get("RuboCop::Formatter::#{formatters[format]}")
      end

      def formatters
        rubocop_formatters.map do |key, value|
          [key.gsub(/[\[\]]/, '').to_sym, value]
        end.to_h
      end

      def rubocop_formatters
        RuboCop::Formatter::FormatterSet::BUILTIN_FORMATTERS_FOR_KEYS
      end

      def print_offenses_for_check(check)
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
