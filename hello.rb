@hello = 'world'

# 5 / 0

=begin
features = $LOADED_FEATURES.dup
result = Sketchup.require 'C:/Users/Thomas/SourceTree/extension-sources/hello.rb'
new_features = $LOADED_FEATURES - features
puts
p result
p new_features
=end


=begin
features = $LOADED_FEATURES.dup
result = Sketchup.require 'C:/Users/Thomas/SourceTree/extension-sources/Hello.rb'
new_features = $LOADED_FEATURES - features
puts
p result
p new_features
=end

=begin
features = $LOADED_FEATURES.dup
result = Sketchup.require 'C:/Users/Thomas/SourceTree/Extension-sources/hello.rb'
new_features = $LOADED_FEATURES - features
puts
p result
p new_features
=end


=begin
$LOAD_PATH << 'C:/Users/Thomas/SourceTree/extension-sources'
features = $LOADED_FEATURES.dup
result = Sketchup.require 'hello'
new_features = $LOADED_FEATURES - features
puts
p result
p new_features
=end

=begin
features = $LOADED_FEATURES.dup
result = Sketchup.require 'HELLO'
new_features = $LOADED_FEATURES - features
puts
p result
p new_features
=end

# true
# ["C:/Users/Thomas/SourceTree/extension-sources/HELLO.rb"]
# => ["C:/Users/Thomas/SourceTree/extension-sources/HELLO.rb"]
