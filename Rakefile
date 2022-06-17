require 'rake/testtask'
require 'yard'

Rake::TestTask.new do |task|
  task.libs << "src"
  task.libs << "tests/standalone/helpers"
  task.pattern = "tests/standalone/**/*_test.rb"
end

YARD::Rake::YardocTask.new(:doc)

# TODO: This appear to also generate the HTML output. So can this become `:doc`?
YARD::Rake::YardocTask.new(:undoc) do |task|
  task.stats_options << '--list-undoc'
end

task :default => [:test, :undoc]
