import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/book_model.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  Map<String, int> _categoryCount = {};
  Map<String, int> _categoryIssued = {};
  bool _isLoading = true;

  final List<Color> _colors = [
    const Color(0xFF2E7D52),
    Colors.orange,
    Colors.blue,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
    Colors.pink,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final booksJson = prefs.getString('books_list') ?? '[]';
    final issuesJson = prefs.getString('issues_list') ?? '[]';
    final List booksDecoded = jsonDecode(booksJson);
    final List issuesDecoded = jsonDecode(issuesJson);

    final books = booksDecoded.map((e) => BookModel.fromMap(e)).toList();

    Map<String, int> categoryCount = {};
    Map<String, int> categoryIssued = {};

    for (var book in books) {
      categoryCount[book.genre] = (categoryCount[book.genre] ?? 0) + 1;
    }

    for (var issue in issuesDecoded) {
      final bookId = issue['bookId'] ?? '';
      final book = books.firstWhere(
        (b) => b.id == bookId,
        orElse: () =>
            BookModel(id: '', title: '', author: '', isbn: '', genre: 'Other'),
      );
      if (book.id.isNotEmpty) {
        categoryIssued[book.genre] = (categoryIssued[book.genre] ?? 0) + 1;
      }
    }

    setState(() {
      _categoryCount = categoryCount;
      _categoryIssued = categoryIssued;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D52)),
          )
        : _categoryCount.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 80,
                  color: Colors.green.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No categories found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add books to see categories',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadCategories,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categoryCount.keys.length,
              itemBuilder: (context, index) {
                final genre = _categoryCount.keys.elementAt(index);
                final total = _categoryCount[genre] ?? 0;
                final issued = _categoryIssued[genre] ?? 0;
                final available = total - issued;
                final color = _colors[index % _colors.length];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.category,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                genre,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$total Books',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildCategorystat(
                                'Total',
                                total.toString(),
                                Icons.menu_book,
                                color,
                              ),
                            ),
                            Expanded(
                              child: _buildCategorystat(
                                'Issued',
                                issued.toString(),
                                Icons.book_outlined,
                                Colors.orange,
                              ),
                            ),
                            Expanded(
                              child: _buildCategorystat(
                                'Available',
                                available.toString(),
                                Icons.check_circle_outline,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: total > 0 ? issued / total : 0,
                            backgroundColor: color.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
  }

  Widget _buildCategorystat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
