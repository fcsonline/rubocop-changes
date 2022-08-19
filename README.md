# Rubocop::Changes

[![Gem Version](https://img.shields.io/gem/v/rubocop-changes)](https://rubygems.org/gems/rubocop-changes)
[![Build Status](https://github.com/fcsonline/rubocop-changes/actions/workflows/ci.yml/badge.svg)](https://github.com/fcsonline/rubocop-changes/actions/workflows/ci.yml)

`rubocop-changes` runs rubocop and shows only the offenses you introduced since
the fork point of your git branch. Will not complain about existing offenses in
your main branch.

This is useful for CI checks for your pull requests but it could be useful too
for you daily work, to know new offenses created by you.

Internally `rubocop-changes` runs `rubocop` and a `git diff` and does the
intersection of line numbers to know the new offenses you are introducing to
you master branch.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rubocop-changes'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rubocop-changes

## Usage

    $ bundle exec rubocop-changes -b master
    
When you run `rubocop-changes`, you have to specify which is your base branch with `-b` argument. By default is `main`. If you want to avoid to pass this argument everytime you execute this command, you can also set the `RUBOCOP_CHANGES_BASE_BRANCH` environment variable.

## Other gems

There are similar projects out there, like
[rubocop-git](https://github.com/m4i/rubocop-git),
[diffcop](https://github.com/yohira0616/diffcop),
[nexocop](https://github.com/SimpleNexus/nexocop), but not all of them offer
differences at line level. Only
[rubocop-git](https://github.com/m4i/rubocop-git) offer this nice feature but
you have to craft the commit id to get the proper fork point of your pull
request.

rubocop-changes does this diff out of the box without specify any commit id. If
you want to get the offense comparing from one specific commit, you can pass
the argument `commit` to the command.

## Ideas

Those are some ideas to improve `rubocop-changes`:

- [ ] Let users specify the rubocop config file

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fcsonline/rubocop-changes. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rubocop::Changes project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/fcsonline/rubocop-changes/blob/master/CODE_OF_CONDUCT.md).
