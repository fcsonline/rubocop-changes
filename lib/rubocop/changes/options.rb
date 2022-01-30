# frozen_string_literal: true

require 'optparse'

module Rubocop
  module Changes
    class Options
      Options = Struct.new(:format, :quiet, :commit, :auto_correct, :base_branch)

      def initialize
        @args = Options.new(:simple, false, nil, false, 'main') # Defaults
      end

      def parse!
        OptionParser.new do |opts|
          opts.banner = 'Usage: rubocop-changes [options]'

          parse_formatter!(opts)
          parse_commit!(opts)
          parse_quiet!(opts)
          parse_auto_correct!(opts)
          parse_help!(opts)
          parse_version!(opts)
          parse_base_branch!(opts)
        end.parse!

        args
      end

      private

      attr_reader :args

      def formatter_values
        formatters = RuboCop::Formatter::FormatterSet::BUILTIN_FORMATTERS_FOR_KEYS

        formatters.keys.map do |key|
          key.gsub(/[\[\]]/, '').to_sym
        end
      end

      def parse_formatter!(opts)
        opts.on(
          '-f',
          '--formatter [FORMATER]',
          formatter_values,
          "Select format type (#{formatter_values.join(', ')})"
        ) do |t|
          args.format = t
        end
      end

      def parse_commit!(opts)
        opts.on(
          '-c',
          '--commit [COMMIT_ID]',
          'Compare from some specific point on git history'
        ) do |c|
          args.commit = c
        end
      end

      def parse_quiet!(opts)
        opts.on('-q', '--quiet', 'Be quiet') do |v|
          args.quiet = v
        end
      end

      def parse_auto_correct!(opts)
        opts.on('-a', '--auto-correct', 'Auto correct errors') do |v|
          args.auto_correct = v
        end
      end

      def parse_base_branch!(opts)
        opts.on('-b', '--base_branch', 'Base branch to compare') do |v|
          args.base_branch = v
        end
      end

      def parse_help!(opts)
        opts.on('-h', '--help', 'Prints this help') do
          puts opts
          exit
        end
      end

      def parse_version!(opts)
        opts.on('--version', 'Display version') do
          puts Rubocop::Changes::VERSION
          exit 0
        end
      end
    end
  end
end
