Algorithm question:

Given a list of item, how can you move a non-continuous sub-set of the items to another position?

```
item1
item2 <--+
item3    |
item4 * -+
item5    |
item6 * -+
item7
```

Expected result:
```
item1
item4
item6
item2
item3
item5
item7
```


```
item1
item2 * -+
item3 * -+ <- target
item4 * -+
item5    |
item6 * -+
item7
```

Expected result:
```
item1
item2
item3
item4
item6
item5
item7
```




```
item1 * -+
item2    +
item3 * -+ <- target
item4 * -+
item5    |
item6 * -+
item7
```

Expected result:
```
item2
item1
item3
item4
item6
item5
item7
```

```
0 0 item1 * -1
1 1 item2    1
2 2 item3 *  0 <- target
3 3 item4 *  0
4 4 item5    1
5 5 item6 * -1
6 6 item7    0
```
```
0 1 item2
1 0 item1 *
2 2 item3 *
3 3 item4 *
4 5 item6 *
5 4 item5
6 6 item7
```
