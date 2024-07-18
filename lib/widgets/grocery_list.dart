import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];

  var _isLoading = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    _isLoading = true;
    final url = Uri.https(
      "shopping-list-app-8cbf5-default-rtdb.firebaseio.com",
      "shopping-list.json",
    );

    final response = await http.get(url);
    if (response.statusCode >= 400) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load data. Please try again later.';
      });
      return;
    }

    if (response.body == "null") {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
            (catItem) => catItem.value.title == item.value['category'],
          )
          .value;
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value["name"],
          quantity: item.value["quantity"],
          category: category,
        ),
      );
    }
    setState(() {
      _groceryItems = loadedItems;
      _isLoading = false;
    });
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      CupertinoPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) return;
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _showDeleteModal(GroceryItem item) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20.0),
          color: Theme.of(context).colorScheme.surface,
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delete Item',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text('Are you sure you want to delete "${item.name}"?'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      _deleteItem(item);
                      Navigator.pop(context);
                    },
                    child: const Text("Delete"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteItem(GroceryItem item) async {
    setState(() {
      _groceryItems.remove(item);
      _isLoading = false;
    });
    final url = Uri.https(
      "shopping-list-app-8cbf5-default-rtdb.firebaseio.com",
      "shopping-list/${item.id}.json",
    );

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(_groceryItems.indexOf(item), item);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: Text(
            "Sorry...No items added yet!",
            style: Theme.of(context).textTheme.bodyLarge,
          ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(CupertinoIcons.add),
          ),
        ],
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : _groceryItems.isEmpty
              ? content
              : ListView.builder(
                  itemCount: _groceryItems.length,
                  itemBuilder: (ctx, index) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: InkWell(
                      onTap: () {
                        _showDeleteModal(_groceryItems[index]);
                      },
                      child: Card(
                        child: ListTile(
                          leading: Container(
                            color: _groceryItems[index].category.color,
                            width: 20,
                            height: 20,
                          ),
                          title: Text(
                            _groceryItems[index].name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          trailing: Text(
                            _groceryItems[index].quantity.toString(),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
