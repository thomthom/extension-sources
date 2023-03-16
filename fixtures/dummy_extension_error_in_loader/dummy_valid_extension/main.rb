module TestExample

  def self.hello
    'world'
  end

  5 / 0 # Intentional error - triggering LoadError

end # module
