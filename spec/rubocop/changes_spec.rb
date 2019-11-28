# frozen_string_literal: true

RSpec.describe Rubocop::Changes do
  it 'has a version number' do
    expect(Rubocop::Changes::VERSION).not_to be nil
  end
end
