require 'json'

Item = Struct.new(:name, :index, :selected, keyword_init: true)

target_index = ARGV[0]&.to_i || 5

items = [
  Item.new(name: 'item0', index: 0, selected: false), # 0
  Item.new(name: 'item1', index: 1, selected: false), # 1
  Item.new(name: 'item2', index: 2, selected: true),  # 2
  Item.new(name: 'item3', index: 3, selected: false), # 3
  Item.new(name: 'item4', index: 4, selected: true),  # 4
  Item.new(name: 'item5', index: 5, selected: false), # 5
  Item.new(name: 'item6', index: 6, selected: false), # 6
]
expected = [0, 1, 3, 2, 4, 5, 6].map { |i| items[i] }

puts
puts "Original:"
items.each { |item| p item.to_h }

# item0
# item1
# item2 *
# item3 *
# item4 <- insert: (after)
# item5 *
# item6
#
# item0 <- first: 0
# item1
# item2 *
# item3 *
# item4 <- insert: 4 (after)
# item5 *
# item6
# ----- <- last: 7
#
# stable_partition [first, insert)
# stable_partition [insert, last)
#
# item0
# item1
# item2 *
# item3 *
# item4 <- insert: (after)
# item5 *
# item6
#
# Ruby Ranges:
# (0..6) == [0..6]  <- inclusive last
# (0...6) == [0..6) <- exclusive last

upper = (0...target_index)
sorted = items.sort_by { |item|
  in_upper = upper.include?(item.index)
  to_top_of_partition = if in_upper
    item.selected ? 1 : 0
  else
    item.selected ? 0 : 1
  end
  primary = in_upper ? 0 : 1
  secondary = to_top_of_partition
  tertiary = item.index
  [primary, secondary, tertiary]
}

puts
puts "Moved:"
puts "#{items.select(&:selected).map(&:index)} to #{target_index}"

puts
puts "Actual:"
sorted.each { |item| p item.to_h }

if ARGV.empty?
  puts
  puts "Expected:"
  expected.each { |item| p item.to_h }

  puts
  puts "Match: #{sorted == expected}"
end
