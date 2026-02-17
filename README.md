# Mirrorfile

Clone git repositories into a local `mirrors/` folder and keep them updated. Uses a `Mirrorfile` with Bundler-like syntax.

## Why use this

- You want to vendor gems or libraries without git submodules
- You need local copies of repos for reference or offline work
- You want Zeitwerk to autoload code from external repos in Rails

## Why not use this

- Git submodules already work fine for you
- You need pinned versions or tags (this just pulls `HEAD`)
- You want proper dependency management (use Bundler)


## Install
```ruby
gem install mirrorfile
```

## Usage
```bash
mirror init      # creates Mirrorfile, .gitignore entry, zeitwerk initializer (Rails only)
mirror install   # clones missing repos
mirror update    # pulls existing repos
mirror list      # shows defined mirrors
```

## Example Mirrorfile

You can change sources mid-file:

```ruby
# frozen_string_literal: true

# Rails ecosystem
source "https://github.com"

mirror "rails/rails", as: "rails-source"
mirror "hotwired/turbo-rails"
mirror "hotwired/stimulus-rails"

# Internal gems
source "https://git.company.com"

mirror "platform/shared-models", as: "shared-models"
mirror "platform/api-client"

# One-off from different host
mirror "https://gitlab.com/someorg/special-gem"
```

## Contributing

Bug reports and pull requests are welcome on GitHub.

## Development

After checking out the repo:

```bash
bin/setup
bundle exec rake test
```

Generate documentation:

```bash
bundle exec yard doc
bundle exec yard server  # Browse at http://localhost:8808
```

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).
