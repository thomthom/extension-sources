module Helper

  def hello
    super + ' helper'
  end

  def help
    'HELP!'
  end

end


module Foo

  def self.hello
    'foo'
  end

end

p Foo.hello
p Foo.is_a?(Helper)

Foo.singleton_class.prepend(Helper)

p Foo.hello
p Foo.is_a?(Helper)

puts '-' * 30

class Bar
  def hello
    "bar-#{self}"
  end
end

b1 = Bar.new
b2 = Bar.new

p b1.hello
p b2.hello

b1.singleton_class.prepend(Helper)

p b1.hello
p b2.hello

p b1.is_a?(Helper)
p b2.is_a?(Helper)
