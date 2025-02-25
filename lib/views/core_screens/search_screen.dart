import 'package:flutter/material.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 35.0, top: 35.0),
            child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {},
                    child: const Text('Home', style: TextStyle(fontSize: 16.0)),
                  ),
                ),
                const Text('  >  ', style: TextStyle(fontSize: 16.0)),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {},
                    child: const Text('Search', style: TextStyle(fontSize: 16.0)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 35.0, top: 25.0, right: 35.0),
            child: searchBar(controller, (value) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Search has been completed'),
                    content: Text('You Searched for: $value'),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget searchBar(TextEditingController controller, ValueChanged<String>? onSubmitted) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
        hintText: 'Search Datasets by name, type or category',
      ),
    );
  }
}
