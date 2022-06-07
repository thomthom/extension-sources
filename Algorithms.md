# Algorithms

## Reorder items

`*` = Selected item

### Original state

```rb
0 item1
1 item2 *
2 item3
3 item4 *
4 item5 *
```
### Desired state

```rb
0 item1
1 item2 *
3 item4 *
4 item5 *
2 item3
```
---------

Move to: item2 (index: 1)

```rb
0 0 item1
1 1 item2 * <- to first non-selected
2 2 item3
3 3 item4 *
4 4 item5 * <- iterate from the back
```
```rb
0 0 item1
1 4 item5 * <- remove and insert
2 1 item2 *
3 2 item3
4 3 item4 *
```
```rb
0 0 item1
4 3 item4 * <- remove and insert
1 4 item5 * # done
2 1 item2 *
3 2 item3
```
```rb
0 0 item1
4 3 item4 *
1 4 item5 * # done
2 1 item2 * # done
3 2 item3 <- leave as-is
```
```rb
0 0 item1
2 1 item2 * <- remove and insert
4 3 item4 * # done
1 4 item5 * # done
3 2 item3   # done
```
