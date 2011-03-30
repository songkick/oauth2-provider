spec = Gem::Specification.new do |s|
  s.name              = "oauth2-provider"
  s.version           = "0.1.0"
  s.summary           = "Simple OAuth 2.0 provider toolkit"
  s.author            = "James Coglan"
  s.email             = "james@songkick.com"
  s.homepage          = "http://www.songkick.com"

  s.has_rdoc          = true
  s.extra_rdoc_files  = %w(README.rdoc)
  s.rdoc_options      = %w(--main README.rdoc)

  s.files             = %w(README.rdoc) + Dir.glob("{spec,lib,example}/**/*")
  s.require_paths     = ["lib"]

  s.add_dependency("bcrypt-ruby")
  s.add_dependency("activerecord")
  s.add_dependency("json")

  s.add_development_dependency("rspec")
  s.add_development_dependency("sqlite3-ruby")
  s.add_development_dependency("sinatra")
  s.add_development_dependency("thin")
  s.add_development_dependency("factory_girl")
end

