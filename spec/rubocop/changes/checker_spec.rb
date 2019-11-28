# frozen_string_literal: true

require 'rubocop/changes/checker'
require 'rubocop/changes/shell'

RSpec.describe Rubocop::Changes::Checker do
  subject { described_class.new.run }

  context 'when the for point is not known' do
    it 'raises and exception' do
      expect(Rubocop::Changes::Shell).to receive(:run).with(
        'git merge-base HEAD origin/master'
      ).and_return('')

      expect { subject }.to raise_error(Rubocop::Changes::UnknownForkPointError)
    end
  end

  context 'when the for point is known' do
    let(:diff_files) do
      %w[lib/rubocop/changes/checker.rb spec/rubocop/changes/checker_spec.rb]
    end

    let(:git_diff) { File.read('spec/rubocop/changes/sample.diff') }
    let(:offenses) { File.read('spec/rubocop/changes/rubocop.json') }

    let(:total_offenses) do
      JSON.parse(offenses)['files'].map do |file|
        file['offenses'].count
      end.inject(:+)
    end

    it 'run a git diff' do
      expect(Rubocop::Changes::Shell).to receive(:run).with(
        'git merge-base HEAD origin/master'
      ).and_return('deadbeef')

      expect(Rubocop::Changes::Shell).to receive(:run).with(
        'git diff deadbeef'
      ).and_return(git_diff)

      expect(Rubocop::Changes::Shell).to receive(:run).with(
        "bundle exec rubocop -f j #{diff_files.join(' ')}"
      ).and_return(offenses)

      expect(total_offenses).to be(2)
      expect(subject.size).to be(0)
    end
  end
end
