Gem::Specification.new do |spec|
  spec.name          = "buda_api"
  spec.version       = "1.0.0"
  spec.authors       = ["Buda API Ruby SDK"]
  spec.email         = ["pablob0798@gmail.com"]

  spec.summary       = "Ruby SDK for Buda.com trading API"
  spec.description   = "A comprehensive Ruby SDK for interacting with Buda.com cryptocurrency exchange API with debugging, error handling, and comprehensive examples"
  spec.homepage      = "https://github.com/PabloB07/buda-api-ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/PabloB07/buda-api-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/PabloB07/buda-api-ruby/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-retry", "~> 2.0"
  spec.add_dependency "logger", "~> 1.5"
  spec.add_dependency "json", "~> 2.6"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "vcr", "~> 6.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
  spec.add_development_dependency "yard", "~> 0.9"
end