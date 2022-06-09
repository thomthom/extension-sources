require 'json'

Item = Struct.new(:name, :index, :selected, keyword_init: true)

target_index = 5

items = [
  Item.new(name: 'item0', index: 0, selected: false), # 0
  Item.new(name: 'item1', index: 1, selected: false), # 1
  Item.new(name: 'item2', index: 2, selected: true),  # 2
  Item.new(name: 'item3', index: 3, selected: false), # 3
  Item.new(name: 'item4', index: 4, selected: true),  # 4
  Item.new(name: 'item5', index: 5, selected: false), # 5
  Item.new(name: 'item6', index: 6, selected: false), # 6
]
expected = [0, 1, 3, 5, 2, 4, 6].map { |i| items[i] }

puts
puts "Original:"
items.each { |item| p item.to_h }

first_selected_index = items.index { |item| item.selected } || 0
last_selected_index = items.rindex { |item| item.selected } || [item.size - 1, 0].max
lower_bound_index = [first_selected_index, target_index].min
upper_bound_index = [last_selected_index, target_index].max
movable_range = (lower_bound_index..upper_bound_index)

puts
p [:target_index, target_index]
p [:first_selected_index, first_selected_index]
p [:last_selected_index, last_selected_index]
p [:lower_bound_index, lower_bound_index]
p [:upper_bound_index, upper_bound_index]
p [:movable_range, movable_range]

SORT_MOVE_UP = -1
SORT_NO_MOVE = 0
SORT_MOVE_DOWN = 1

sorted = items.dup
items.each { |item|
  if item.selected
    sorted.delete(item)
    sorted.insert(target_index, item)
  end
}

puts
puts "Actual:"
sorted.each { |item| p item.to_h }

puts
puts "Expected:"
expected.each { |item| p item.to_h }

puts
puts "Match: #{sorted == expected}"
