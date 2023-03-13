Gem::Specification.new do |s|
  s.name              = 'songkick-oauth2-provider'
  s.version           = '0.11.0'
  s.summary           = 'Simple OAuth 2.0 provider toolkit'
  s.author            = 'James Coglan'
  s.email             = 'james@songkick.com'
  s.homepage          = 'http://github.com/songkick/oauth2-provider'

  s.extra_rdoc_files  = %w[README.rdoc]
  s.rdoc_options      = %w[--main README.rdoc]

  s.files             = %w[History.txt README.rdoc] + Dir.glob('{example,lib,spec}/**/*.{css,erb,rb,rdoc,ru}')
  s.require_paths     = ['lib']

  s.add_dependency 'activerecord', '6.1.4.1'
  s.add_dependency 'bcrypt'
  s.add_dependency 'json'
  s.add_dependency 'rack'

  s.add_development_dependency 'appraisal', '2.4.1'
  s.add_development_dependency 'factory_bot'
  s.add_development_dependency 'i18n', '~> 1.6'
  s.add_development_dependency 'mysql2' if ENV['DB'] == 'mysql' # version locked by ActiveRecord
  s.add_development_dependency 'pg', '~> 0.18.4' if ENV['DB'] == 'postgres'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'sinatra', '~> 1.3'
  s.add_development_dependency 'sqlite3', '~> 1.6'
  s.add_development_dependency 'thin'
  s.add_development_dependency 'protected_attributes_continued'
end
