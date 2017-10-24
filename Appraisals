if RUBY_VERSION < '1.9'
  appraise 'activerecord_2_2' do
    gem 'activerecord', '~> 2.2.0'
    gem 'factory_girl', '~> 2.3.0'
    gem 'rake', '~> 0.8.7'
  end
end

appraise 'activerecord_2_3' do
  gem 'activerecord', '~> 2.3.0'
end

appraise 'activerecord_3_0' do
  gem 'activerecord', '~> 3.0.0'
end

appraise 'activerecord_3_1' do
  gem 'activerecord', '~> 3.1.0'
end

appraise 'activerecord_3_2' do
  gem 'activerecord', '~> 3.2.0'
end

if RUBY_VERSION >= '1.9'
  appraise 'activerecord_4_0' do
    gem 'activerecord', '~> 4.0.0'
    gem 'mysql', '~> 2.9.0' if ENV['DB'] == 'mysql'
  end

  appraise 'activerecord_4_1' do
    gem 'activerecord', '~> 4.1.0'
    gem 'mysql', '~> 2.9.0' if ENV['DB'] == 'mysql'
  end
end
