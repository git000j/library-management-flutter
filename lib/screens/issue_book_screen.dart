import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/book_model.dart';
import '../models/issue_model.dart';

class IssueBookScreen extends StatefulWidget {
  const IssueBookScreen({super.key});

  @override
  State<IssueBookScreen> createState() => _IssueBookScreenState();
}

class _IssueBookScreenState extends State<IssueBookScreen> {
  List<IssueModel> _issues = [];
  List<BookModel> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final booksJson = prefs.getString('books_list') ?? '[]';
    final issuesJson = prefs.getString('issues_list') ?? '[]';
    final List booksDecoded = jsonDecode(booksJson);
    final List issuesDecoded = jsonDecode(issuesJson);
    setState(() {
      _books = booksDecoded.map((e) => BookModel.fromMap(e)).toList();
      _issues =
          issuesDecoded.map((e) => IssueModel.fromMap(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _markReturned(String issueId) async {
    final prefs = await SharedPreferences.getInstance();
    final index = _issues.indexWhere((i) => i.id == issueId);
    if (index != -1) {
      _issues[index].isReturned = true;
      await prefs.setString('issues_list',
          jsonEncode(_issues.map((i) => i.toMap()).toList()));
      setState(() {});
      _showSnackBar('Book marked as returned!', Colors.green);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: color, content: Text(message)),
    );
  }

  void _showIssueForm() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    BookModel? selectedBook;
    DateTime issueDate = DateTime.now();
    DateTime returnDate = DateTime.now().add(const Duration(days: 14));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Issue Book',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D52))),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),
                _formLabel('Select Book'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<BookModel>(
                      isExpanded: true,
                      hint: const Text('Choose a book'),
                      value: selectedBook,
                      items: _books
                          .map((b) => DropdownMenuItem(
                                value: b,
                                child: Text(b.title,
                                    overflow:
                                        TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setModalState(() => selectedBook = val),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _formLabel('User Name'),
                const SizedBox(height: 8),
                _formField(nameController, 'Enter user name',
                    Icons.person_outline),
                const SizedBox(height: 16),
                _formLabel('User Email'),
                const SizedBox(height: 8),
                _formField(emailController, 'Enter user email',
                    Icons.email_outlined),
                const SizedBox(height: 16),
                _formLabel('Phone Number'),
                const SizedBox(height: 8),
                _formField(phoneController, 'Enter phone number',
                    Icons.phone_outlined),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _formLabel('Issue Date'),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: issueDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setModalState(
                                    () => issueDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F8F4),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Color(0xFF2E7D52)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${issueDate.day}/${issueDate.month}/${issueDate.year}',
                                    style: const TextStyle(
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _formLabel('Return Date'),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: returnDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setModalState(
                                    () => returnDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F8F4),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Color(0xFF2E7D52)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${returnDate.day}/${returnDate.month}/${returnDate.year}',
                                    style: const TextStyle(
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (selectedBook == null ||
                          nameController.text.isEmpty ||
                          emailController.text.isEmpty ||
                          phoneController.text.isEmpty) {
                        _showSnackBar(
                            'Please fill all fields', Colors.red);
                        return;
                      }
                      final prefs =
                          await SharedPreferences.getInstance();
                      final newIssue = IssueModel(
                        id: DateTime.now()
                            .millisecondsSinceEpoch
                            .toString(),
                        bookId: selectedBook!.id,
                        bookTitle: selectedBook!.title,
                        userName: nameController.text,
                        userEmail: emailController.text,
                        userPhone: phoneController.text,
                        issueDate:
                            '${issueDate.day}/${issueDate.month}/${issueDate.year}',
                        returnDate:
                            '${returnDate.day}/${returnDate.month}/${returnDate.year}',
                      );
                      _issues.add(newIssue);
                      await prefs.setString(
                          'issues_list',
                          jsonEncode(_issues
                              .map((i) => i.toMap())
                              .toList()));
                      setState(() {});
                      Navigator.pop(context);
                      _showSnackBar(
                          'Book issued successfully!', Colors.green);
                    },
                    child: const Text('Issue Book',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formLabel(String text) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF2E7D52)));

  Widget _formField(TextEditingController controller, String hint,
      IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF2E7D52)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F4),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showIssueForm,
        backgroundColor: const Color(0xFF2E7D52),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Issue Book',
            style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF2E7D52)))
          : _issues.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book_outlined,
                          size: 80,
                          color: Colors.green.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Text('No books issued yet',
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('Tap + to issue a book',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _issues.length,
                  itemBuilder: (context, index) {
                    final issue = _issues[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.green.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(issue.bookTitle,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.bold)),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4),
                                  decoration: BoxDecoration(
                                    color: issue.isReturned
                                        ? Colors.green
                                            .withOpacity(0.1)
                                        : Colors.orange
                                            .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    issue.isReturned
                                        ? 'Returned'
                                        : 'Issued',
                                    style: TextStyle(
                                        color: issue.isReturned
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            _infoRow(Icons.person_outline,
                                issue.userName),
                            const SizedBox(height: 4),
                            _infoRow(Icons.email_outlined,
                                issue.userEmail),
                            const SizedBox(height: 4),
                            _infoRow(
                                Icons.phone_outlined, issue.userPhone),
                            const SizedBox(height: 4),
                            _infoRow(Icons.calendar_today,
                                'Issued: ${issue.issueDate}'),
                            const SizedBox(height: 4),
                            _infoRow(Icons.event_available,
                                'Return: ${issue.returnDate}'),
                            if (!issue.isReturned) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      _markReturned(issue.id),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Color(0xFF2E7D52)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                                10)),
                                  ),
                                  child: const Text(
                                    'Mark as Returned',
                                    style: TextStyle(
                                        color: Color(0xFF2E7D52)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2E7D52)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey))),
      ],
    );
  }
}