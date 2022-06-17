require 'rake/testtask'

Rake::TestTask.new do |task|
  task.libs << "src"
  task.libs << "tests/standalone/helpers"
  task.pattern = "tests/standalone/**/*_test.rb"
end

task :default => :test
