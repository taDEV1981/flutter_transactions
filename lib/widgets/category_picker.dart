import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class CategoryPicker extends StatefulWidget {
  final Function(String name, Color color, IconData icon) onSave;

  const CategoryPicker({required this.onSave});

  @override
  _CategoryPickerState createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  final TextEditingController _categoryController = TextEditingController();
  Color _selectedColor = Colors.blue;
  IconData _selectedIcon = Icons.category;

  void _selectColor() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pick a Color'),
          content: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
              });
            },
          ),
          actions: [
            TextButton(
              child: Text('Select'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _selectIcon() {
    final List<IconData> icons = [
      Icons.food_bank,
      Icons.shopping_cart,
      Icons.directions_car,
      Icons.movie,
      Icons.payment,
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pick an Icon'),
          content: Wrap(
            children: icons.map((icon) {
              return IconButton(
                icon: Icon(icon),
                onPressed: () {
                  setState(() {
                    _selectedIcon = icon;
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create New Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _categoryController,
            decoration: InputDecoration(
              labelText: 'Category Name',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _selectColor,
            child: Text('Pick Color'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _selectIcon,
            child: Text('Pick Icon'),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('Create'),
          onPressed: () {
            if (_categoryController.text.isNotEmpty) {
              widget.onSave(
                  _categoryController.text, _selectedColor, _selectedIcon);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
