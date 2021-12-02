import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  FirebaseDatabase database = FirebaseDatabase();
  DatabaseReference? _userRef;
  bool createItem = false;
  TextEditingController? con;
  List items = [];
  Map jsonData = {};
  var sc = ScrollController(initialScrollOffset: 50);

  getData() {
    _userRef?.once().then((value) {
      if (value.value == null) {
        items.clear();
        setState(() {});
        return;
      }
      jsonData = value.value['todo'];
      items = jsonData.values.toList();
      items.sort((a, b) => a['id'].compareTo(b['id']));
      sc.jumpTo(50);
      setState(() {});
    });
  }

  updateOrder(Map item, int newOrder) {
    _userRef
        ?.child('todo')
        .child(jsonData.entries.firstWhere((e) => e.value == item).key)
        .update({
      'id': newOrder,
      'title': item['title'],
      'isCompleted': item['isCompleted']
    });
  }

  updateTodo(Map item) {
    try {
      _userRef
          ?.child('todo')
          .child(jsonData.entries.firstWhere((e) => e.value == item).key)
          .update({
        'id': items.firstWhere((e) => e['isCompleted'] == true)['id'] + 1000,
        'title': item['title'],
        'isCompleted': !item['isCompleted']
      });
    } catch (e) {
      _userRef
          ?.child('todo')
          .child(jsonData.entries.firstWhere((e) => e.value == item).key)
          .update({
        'id': 1000 * (items.length + 1),
        'title': item['title'],
        'isCompleted': !item['isCompleted']
      });
    }
    getData();
  }

  removeTodo(Map item) {
    _userRef
        ?.child('todo')
        .child(jsonData.entries.firstWhere((e) => e.value == item).key)
        .remove();
    getData();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    _userRef = database.reference();

    getData();

    con = TextEditingController();

    sc.addListener(() {
      if (sc.position.atEdge) {
        if (sc.position.pixels == 0) {
          if (sc.position.userScrollDirection == ScrollDirection.forward) {
            openKeyboard();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance?.removeObserver(this);
    con?.dispose();
  }

  FocusNode inputNode = FocusNode();

  void openKeyboard() {
    FocusScope.of(context).requestFocus(inputNode);
  }

  void reorderData(int oldindex, int newindex) {
    if (newindex > oldindex) {
      newindex -= 1;
    }
    if (newindex == items.length - 1) {
      items[oldindex]['isCompleted'] = true;
      updateOrder(items[oldindex], (items[items.length - 1]['id'] + 1000));
      getData();
      return;
    }
    if (items[newindex]['isCompleted']) {
      return;
    }

    updateOrder(items[oldindex], items[newindex]['id']);
    updateOrder(items[newindex], items[oldindex]['id']);
    getData();
  }

  Color? getColor(int i) {
    switch (i) {
      case 0:
        return Colors.red[900];
      case 1:
        return Colors.red[700];
      case 2:
        return Colors.red;
      case 3:
        return Colors.yellow[900];
      case 4:
        return Colors.yellow[700];
      case 5:
        return Colors.yellow;
      case 6:
        return Colors.green[900];
      case 7:
        return Colors.green[700];
      case 8:
        return Colors.green;
      default:
        return Colors.green;
    }
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance?.window.viewInsets.bottom;
    final newValue = bottomInset! > 0.0;
    if (!newValue) {
      setState(() {
        sc.jumpTo(50);
      });
    } else {
      openKeyboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomScrollView(
          controller: sc,
          slivers: [
            creatItemBox(),
            listDataItems(),
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 1000,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter listDataItems() {
    return SliverToBoxAdapter(
      child: items.isEmpty
          ? const SizedBox(
              height: 500,
              child: Center(
                child: Text(
                  'No Items in your Todo List\nScroll Down to add',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ),
            )
          : ReorderableListView(
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              shrinkWrap: true,
              onReorder: reorderData,
              children: [
                for (final item in items)
                  item['isCompleted']
                      ? Container(
                          key: ValueKey(item),
                          color: item['isCompleted']
                              ? Colors.transparent
                              : getColor(items.indexOf(item)),
                          height: 50,
                          width: double.infinity,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 16.0, top: 12.0),
                            child: Text(
                              item['title'],
                              style: TextStyle(
                                decoration: item['isCompleted']
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: item['isCompleted']
                                    ? Colors.grey
                                    : Colors.white,
                                decorationColor: Colors.grey,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      : Dismissible(
                          key: UniqueKey(),
                          onDismissed: (direction) {
                            if (direction == DismissDirection.startToEnd) {
                              updateTodo(item);
                            } else {
                              removeTodo(item);
                            }
                          },
                          secondaryBackground: Container(
                            color: Colors.red,
                            padding: const EdgeInsets.only(right: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: const [
                                Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 30,
                                )
                              ],
                            ),
                          ),
                          background: Container(
                            color: Colors.green,
                            padding: const EdgeInsets.only(right: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: const [
                                Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 30,
                                )
                              ],
                            ),
                          ),
                          child: ReorderableDelayedDragStartListener(
                            index: items.indexOf(item),
                            key: ValueKey(item),
                            child: Container(
                              color: item['isCompleted']
                                  ? Colors.transparent
                                  : getColor(items.indexOf(item)),
                              height: 50,
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 16.0, top: 12.0),
                                child: Text(
                                  item['title'],
                                  style: TextStyle(
                                    decoration: item['isCompleted']
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    color: item['isCompleted']
                                        ? Colors.grey
                                        : Colors.white,
                                    decorationColor: Colors.grey,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
              ],
            ),
    );
  }

  SliverToBoxAdapter creatItemBox() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.red[900],
        height: 50,
        child: TextField(
          showCursor: false,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          focusNode: inputNode,
          onSubmitted: (a) {
            if (a.isEmpty) {
              return;
            }
            try {
              _userRef?.child('todo').push().set(
                {
                  'id':
                      (items.firstWhere((e) => e['isCompleted'] == true)['id'] -
                          items.length),
                  'title': con?.text.trim(),
                  'isCompleted': false
                },
              );
              con?.clear();
            } catch (e) {
              _userRef?.child('todo').push().set(
                {
                  'id': (1000 * (items.length + 1)),
                  'title': con?.text.trim(),
                  'isCompleted': false
                },
              );
              con?.clear();
            }
            getData();
            sc.jumpTo(50);
          },
          controller: con,
          decoration: const InputDecoration(
            hintText: 'Create Item',
            hintStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}
