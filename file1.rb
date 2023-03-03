path = File.join(__dir__, 'file2.rb')
res = Sketchup.require(path)

puts "file1 require: #{res}"

# Sketchup.require('C:/Users/Thomas/SourceTree/extension-sources/file1.rb')

=begin

Sketchup.require('C:/Users/Thomas/SourceTree/extension-sources/file1.rb')

File load error (C:/Users/Thomas/SourceTree/extension-sources/file2.rb):
Error: #<ZeroDivisionError: divided by 0>
C:/Users/Thomas/SourceTree/extension-sources/file2.rb:1:in `/'
C:/Users/Thomas/SourceTree/extension-sources/file2.rb:1:in `<top (required)>'
C:/Users/Thomas/SourceTree/extension-sources/file1.rb:2:in `require'
C:/Users/Thomas/SourceTree/extension-sources/file1.rb:2:in `<top (required)>'
<main>:in `require'
<main>:in `<main>'
SketchUp:in `eval'
file1 require: false
=> true

=end
