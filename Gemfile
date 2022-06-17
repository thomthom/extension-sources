source 'https://rubygems.org'

group :development do
  gem 'debase', '~> 0.2'         # VSCode debugging
  gem 'ruby-debug-ide', '~> 0.7' # VSCode debugging
  gem 'sketchup-api-stubs'       # VSCode SketchUp API insight
  gem 'skippy', '~> 0.5.1.a'
  gem 'solargraph'               # VSCode IDE support
end

group :test do
  gem 'minitest', '~> 5.15.0' # Regression in 5.16.0 causing failure on Ruby 2.7
  gem 'rake', '~> 13.0'
end

group :documentation do
  gem 'commonmarker', '~> 0.23'
  gem 'yard', '~> 0.9'
end

group :analysis do
  gem 'rubocop', '>= 1.30', '< 2.0'
  gem 'rubocop-minitest', '~> 0.20'
  gem 'rubocop-rake', '~> 0.6'
  gem 'rubocop-sketchup', '~> 1.3.0'
end if RUBY_VERSION.to_f > 2.5 # For Ruby 2.5 CI, 1.30 restraint is still applied for some reason.
