spec = Gem::Specification.new do |s|
  s.name              = 'songkick-oauth2-provider'
  s.version           = '0.10.2'
  s.summary           = 'Simple OAuth 2.0 provider toolkit'
  s.author            = 'James Coglan'
  s.email             = 'james@songkick.com'
  s.homepage          = 'http://github.com/songkick/oauth2-provider'

  s.extra_rdoc_files  = %w[README.rdoc]
  s.rdoc_options      = %w[--main README.rdoc]

  s.files             = %w[History.txt README.rdoc] + Dir.glob('{example,lib,spec}/**/*.{css,erb,rb,rdoc,ru}')
  s.require_paths     = ['lib']

  s.add_dependency 'activerecord'
  s.add_dependency 'bcrypt-ruby'
  s.add_dependency 'json'
  s.add_dependency 'rack'

  s.add_development_dependency 'appraisal', '~> 0.4.0'
  s.add_development_dependency 'activerecord', '~> 3.2.0' # The SQLite adapter in 3.1 is broken
  s.add_development_dependency 'mysql', '~> 2.8.0' if ENV['DB'] == 'mysql' # version locked by ActiveRecord
  s.add_development_dependency 'pg' if ENV['DB'] == 'postgres'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'sinatra', '>= 1.3.0'
  s.add_development_dependency 'thin'
  s.add_development_dependency 'factory_girl', '~> 2.0'
end

