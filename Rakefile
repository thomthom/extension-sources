require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "src"
  t.libs << "tests/standalone/helpers"
  t.pattern = "tests/standalone/**/*_test.rb"
end

task :default => :test
