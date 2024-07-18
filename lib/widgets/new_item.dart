import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/category.dart';
import 'package:shopping_list_app/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();

  var _enteredName = "";
  var _enteredQty = 1;
  var _selectedCategory = categories[Categories.vegetables]!;

  var _isSending = false;

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isSending = true;
      });
      final url = Uri.https(
        "shopping-list-app-8cbf5-default-rtdb.firebaseio.com",
        "shopping-list.json",
      );

      try {
        final response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
          },
          body: json.encode(
            {
              "name": _enteredName,
              "quantity": _enteredQty,
              "category": _selectedCategory.title,
            },
          ),
        );

        final Map<String, dynamic> resId = json.decode(response.body);

        if (response.statusCode == 200) {
          // Successfully saved data
          print("Data saved successfully");
          if (!context.mounted) return;
          Navigator.of(context).pop(
            GroceryItem(
              id: resId["name"],
              name: _enteredName,
              quantity: _enteredQty,
              category: _selectedCategory,
            ),
          );
        } else {
          // Failed to save data
          print("Failed to save data: ${response.statusCode}");
          print("Response body: ${response.body}");
        }
      } catch (error) {
        print("Error saving data: $error");
      }
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _enteredName = "";
    _enteredQty = 1;
    _selectedCategory = categories[Categories.vegetables]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add a new item"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text("Name"),
                ),
                validator: (value) => value == null ||
                        value.isEmpty ||
                        value.trim().length <= 1 ||
                        value.trim().length > 50
                    ? "Please enter a valid name between 1 and 50 characters."
                    : null,
                onSaved: (value) {
                  _enteredName = value!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        label: Text("Quantity"),
                      ),
                      initialValue: _enteredQty.toString(),
                      validator: (value) => value == null ||
                              value.isEmpty ||
                              int.tryParse(value) == null ||
                              int.tryParse(value)! <= 0
                          ? "Please enter a valid quantity."
                          : null,
                      onSaved: (value) {
                        _enteredQty = int.parse(value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedCategory,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: category.value.color,
                                ),
                                const SizedBox(width: 6),
                                Text(category.value.title),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        _selectedCategory = value!;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSending ? null : _resetForm,
                    child: const Text("Reset"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isSending ? null : _saveItem,
                    child: _isSending
                        ? const Text("Saving...")
                        : const Text("Add Item"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
