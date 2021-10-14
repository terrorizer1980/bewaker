require_relative 'lib/bewaker/version'

Gem::Specification.new do |spec|
  spec.name          = "bewaker"
  spec.version       = Bewaker::VERSION
  spec.authors       = ["mvgijssel"]
  spec.email         = ["6029816+mvgijssel@users.noreply.github.com"]

  spec.summary       = 'Next generation authorization'
  spec.description   = 'Next generation authorization'
  spec.homepage      = "https://github.com/mvgijssel/bewaker"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mvgijssel/bewaker"
  spec.metadata["changelog_uri"] = "https://github.com/mvgijssel/bewaker/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'gem-release', '2.2.1'
  spec.add_dependency 'activerecord', '>= 5.0.0', '< 6.0.4'
  spec.add_dependency 'pg'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-nav'
  spec.add_development_dependency 'pry-doc'
  spec.add_development_dependency 'pry-rescue'
  spec.add_development_dependency 'pry-stack_explorer'
  spec.add_development_dependency 'pry-alias'
end
