# frozen_string_literal: true

require 'rubocop/changes/checker'
require 'rubocop/changes/shell'

RSpec.describe Rubocop::Changes::Checker do
  let(:commit) { nil }
  let(:auto_correct) { false }
  let(:local_git_root_path) { Dir.pwd }

  subject do
    described_class.new(
      format: :simple,
      quiet: false,
      commit: commit,
      auto_correct: auto_correct,
      base_branch: 'master'
    ).run
  end

  before do
    allow(Rubocop::Changes::Shell).to receive(:run)
      .with("git rev-parse --show-toplevel").and_return(local_git_root_path)
  end

  context 'when the fork point is not known' do
    it 'raises an exception' do
      expect(Rubocop::Changes::Shell).to receive(:run).with(
        'git merge-base HEAD origin/master'
      ).and_return('')

      expect do
        subject
      end.to raise_error(Rubocop::Changes::UnknownForkPointError)
    end

    context 'by given commit id' do
      let(:commit) { 'deadbeef' }

      it 'raises an exception' do
        expect(Rubocop::Changes::Shell).to receive(:run).with(
          'git log -n 1 --pretty=format:"%h" deadbeef'
        ).and_return('')

        expect do
          subject
        end.to raise_error(Rubocop::Changes::UnknownForkPointError)
      end
    end
  end

  context 'when the fork point is known' do
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

    it 'runs a git diff' do
      expect(Rubocop::Changes::Shell).to receive(:run).with(
        'git merge-base HEAD origin/master'
      ).and_return('deadbeef')

      expect(Rubocop::Changes::Shell).to receive(:run).with(
        'git diff deadbeef'
      ).and_return(git_diff)

      expect(Rubocop::Changes::Shell).to receive(:run).with(
        "rubocop --force-exclusion -f j #{diff_files.join(' ')}"
      ).and_return(offenses)

      expect(total_offenses).to be(2)
      expect(subject.size).to be(0)
    end

    context 'by given commit id' do
      let(:commit) { 'deadbeef' }

      it 'runs a git diff' do
        expect(Rubocop::Changes::Shell).to receive(:run).with(
          'git log -n 1 --pretty=format:"%h" deadbeef'
        ).and_return('deadbeef')

        expect(Rubocop::Changes::Shell).to receive(:run).with(
          'git diff deadbeef'
        ).and_return(git_diff)

        expect(Rubocop::Changes::Shell).to receive(:run).with(
          "rubocop --force-exclusion -f j #{diff_files.join(' ')}"
        ).and_return(offenses)

        expect(total_offenses).to be(2)
        expect(subject.size).to be(0)
      end
    end

    context 'when auto_correct flag is not present' do
      it do
        expect(Rubocop::Changes::Shell).to receive(:run).with(
          'git merge-base HEAD origin/master'
        ).and_return('deadbeef')

        expect(Rubocop::Changes::Shell).to receive(:run).with(
          'git diff deadbeef'
        ).and_return(git_diff)

        expect(Rubocop::Changes::Shell).to receive(:run).with(
          "rubocop --force-exclusion -f j #{diff_files.join(' ')}"
        ).and_return(offenses)

        expect(subject.size).to be(0)
      end
    end

    context 'when auto_correct flag is present' do
      let(:auto_correct) { true }

      it do
        expect(Rubocop::Changes::Shell).to receive(:run).with(
          'git merge-base HEAD origin/master'
        ).and_return('deadbeef')

        expect(Rubocop::Changes::Shell).to receive(:run).with(
          'git diff deadbeef'
        ).and_return(git_diff)

        expect(Rubocop::Changes::Shell).to receive(:run).with(
          "rubocop --force-exclusion -f j #{diff_files.join(' ')} -A"
        ).and_return(offenses)

        expect(subject.size).to be(0)
      end
    end
  end

  describe "running from a sub-folder" do
    let(:diff_files) do
      %w[lib/rubocop/changes/checker.rb spec/rubocop/changes/checker_spec.rb]
    end

    let(:git_diff) { File.read('spec/rubocop/changes/monorepo_sample.diff') }
    let(:offenses) { File.read('spec/rubocop/changes/monorepo_rubocop.json') }

    let(:total_offenses) do
      JSON.parse(offenses)['files'].map do |file|
        file['offenses'].count
      end.inject(:+)
    end

    before do
      allow(Dir).to receive(:pwd).and_return(File.join(local_git_root_path, "backend"))
    end

    it 'runs a git diff' do
      expect(Rubocop::Changes::Shell).to receive(:run).with(
        'git merge-base HEAD origin/master'
      ).and_return('deadbeef')

      expect(Rubocop::Changes::Shell).to receive(:run).with(
        'git diff deadbeef'
      ).and_return(git_diff)

      expect(Rubocop::Changes::Shell).to receive(:run).with(
        "rubocop --force-exclusion -f j #{diff_files.join(' ')}"
      ).and_return(offenses)

      expect(total_offenses).to be(2)
      expect(subject.size).to be(0)
    end
  end
end
