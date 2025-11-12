import 'package:flutter/material.dart';
import 'package:air/models/task_model.dart';

class CategorySelector extends StatelessWidget {
  final TaskCategory selectedCategory;
  final Function(TaskCategory) onCategorySelected;

  const CategorySelector({
    Key? key,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: TaskCategory.values.map((category) {
          final isSelected = selectedCategory == category;
          return GestureDetector(
            onTap: () => onCategorySelected(category),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? getCategoryColor(category).withOpacity(0.2) 
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? getCategoryColor(category) 
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    getCategoryIcon(category),
                    color: isSelected 
                        ? getCategoryColor(category) 
                        : Colors.grey,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    getCategoryName(category),
                    style: TextStyle(
                      color: isSelected 
                          ? getCategoryColor(category) 
                          : Colors.grey,
                      fontWeight: isSelected 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
} 