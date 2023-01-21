module BenchmarkRunner

  PROJECT_PATH = File.expand_path('..', __dir__)
  SOURCE_PATH = File.join(PROJECT_PATH, 'src')

  $LOAD_PATH << SOURCE_PATH

  USE_IPS = ARGV.include?('ips')
  METHOD = USE_IPS ? :ips : :bmbm

  if USE_IPS
    require 'benchmark/ips'
  else
    require 'benchmark'
  end

  def self.start(&block)
    Benchmark.send(METHOD) { |x|
      block.call(x)
      x.compare! if USE_IPS
    }
  end

end

# Define the nested extension namespace.
module TT
  module Plugins
    module ExtensionSources
    end
  end
end
