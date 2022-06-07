require 'json'

target_index = 2

items = [
  { name: 'item0', selected: false }, # 0
  { name: 'item1', selected: false }, # 1
  { name: 'item2', selected: false }, # 2
  { name: 'item3', selected: true },  # 3
  { name: 'item4', selected: false }, # 4
  { name: 'item5', selected: true },  # 5
  { name: 'item6', selected: true },  # 6
]
expected = [0, 1, 3, 5, 6, 2, 4].map { |i| items[i] }

# lower_bound_index = items.each.with_index.find { |item, index|
#   # p [item, index]
#   item[:selected] && index <= target_index
# }&.last || target_index
first_selected_index = items.find_index { |item| item[:selected] } || 0
lower_bound_index = [first_selected_index, target_index].min

p [:target_index, target_index]
p [:lower_bound_index, lower_bound_index]

SORT_MOVE_UP = -1
SORT_NO_MOVE = 0
SORT_MOVE_DOWN = 1

# puts
sorted = items.each.with_index.sort { |current, previous|
  item_current, index_current = current
  item_previous, index_previous = previous

  # Keep the items above the lower bound index.
  # This effectively splits the list in half;
  # * Everything above the insertion point
  # * Everything else
  is_movable_current = index_current >= lower_bound_index
  is_movable_previous = index_previous >= lower_bound_index
  next -1 if !is_movable_current && is_movable_previous
  next 1 if is_movable_current && !is_movable_previous

  # Everything that is below the insertion point is then grouped and sorted
  # first by selected, then by index.
  # Selected items are moved to the top of this sub-list, while un-selected
  # ends up at the bottom.
  if is_movable_current
    selected_current = item_current[:selected]
    selected_previous = item_previous[:selected]
    next -1 if selected_current && !selected_previous
    next 1 if !selected_current && selected_previous
  end

  # This resolves any ambiguity, defaulting to the unique
  # indices of each item. This should never return 0, ensuring
  # that the sort is stable.
  index_current <=> index_previous
}&.map(&:first)

puts
sorted.each { |item| p item }

puts
expected.each { |item| p item }
