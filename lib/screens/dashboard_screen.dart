import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/book_model.dart';
import '../models/issue_model.dart';
import 'categories_screen.dart';
import 'issue_book_screen.dart';
import 'admin_screen.dart';
import 'analytics_screen.dart';
import 'add_book_screen.dart';
import 'book_detail_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _userName = '';
  String _userEmail = '';
  int _totalBooks = 0;
  int _totalIssued = 0;
  int _totalReturned = 0;
  int _totalAvailable = 0;
  List<IssueModel> _recentIssues = [];
  List<BookModel> _books = [];
  List<BookModel> _filteredBooks = [];
  String _searchQuery = '';

  final List<String> _pageTitles = [
    'Dashboard', 'All Books', 'Categories',
    'Issue Management', 'Admin Panel', 'Analytics',
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 'Admin';
    final userEmail = prefs.getString('user_email') ?? '';
    final booksJson = prefs.getString('books_list') ?? '[]';
    final issuesJson = prefs.getString('issues_list') ?? '[]';
    final List booksDecoded = jsonDecode(booksJson);
    final List issuesDecoded = jsonDecode(issuesJson);
    final issues = issuesDecoded.map((e) => IssueModel.fromMap(e)).toList();
    final totalIssued = issues.where((i) => !i.isReturned).length;
    final totalReturned = issues.where((i) => i.isReturned).length;
    final recent = issues.reversed.take(3).toList();
    final books = booksDecoded.map((e) => BookModel.fromMap(e)).toList();
    setState(() {
      _userName = userName;
      _userEmail = userEmail;
      _totalBooks = books.length;
      _totalIssued = totalIssued;
      _totalReturned = totalReturned;
      _totalAvailable = books.length - totalIssued;
      _recentIssues = recent;
      _books = books;
      _filteredBooks = books;
    });
  }

  void _searchBooks(String query) {
    setState(() {
      _searchQuery = query;
      _filteredBooks = query.isEmpty
          ? _books
          : _books.where((b) =>
              b.title.toLowerCase().contains(query.toLowerCase()) ||
              b.author.toLowerCase().contains(query.toLowerCase()) ||
              b.genre.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  Future<void> _deleteBook(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _books.removeWhere((b) => b.id == id);
    await prefs.setString('books_list',
        jsonEncode(_books.map((b) => b.toMap()).toList()));
    _loadStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Book deleted!')));
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    if (mounted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  Widget _getPage() {
    switch (_selectedIndex) {
      case 0: return _buildDashboardHome();
      case 1: return _buildBooksPage();
      case 2: return const CategoriesScreen();
      case 3: return const IssueBookScreen();
      case 4: return const AdminScreen();
      case 5: return const AnalyticsScreen();
      default: return _buildDashboardHome();
    }
  }

  // ============ BOOKS PAGE ============
  Widget _buildBooksPage() {
    return Column(
      children: [
        // Search Bar
        Container(
          color: const Color(0xFF2E7D52),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    onChanged: _searchBooks,
                    decoration: const InputDecoration(
                      hintText: 'Search books...',
                      hintStyle: TextStyle(fontSize: 14),
                      prefixIcon: Icon(Icons.search,
                          color: Color(0xFF2E7D52), size: 20),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AddBookScreen()));
                  _loadStats();
                },
                child: Container(
                  height: 44,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: Color(0xFF2E7D52), size: 20),
                      SizedBox(width: 4),
                      Text('Add',
                          style: TextStyle(
                              color: Color(0xFF2E7D52),
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Count Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text('${_filteredBooks.length} Books',
                  style: const TextStyle(
                      color: Color(0xFF2E7D52),
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              if (_searchQuery.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('for "$_searchQuery"',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13)),
              ],
            ],
          ),
        ),

        // Books List
        Expanded(
          child: _filteredBooks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_outlined,
                          size: 60,
                          color: Colors.grey.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No books yet'
                            : 'No results found',
                        style: const TextStyle(
                            fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: _filteredBooks.length,
                  itemBuilder: (context, index) {
                    final book = _filteredBooks[index];
                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    BookDetailScreen(book: book)));
                        _loadStats();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                              child: book.imageBase64.isNotEmpty
                                  ? Image.memory(
                                      base64Decode(book.imageBase64),
                                      width: 70,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 70,
                                      height: 90,
                                      color: const Color(0xFF2E7D52)
                                          .withOpacity(0.08),
                                      child: const Icon(
                                          Icons.menu_book,
                                          color: Color(0xFF2E7D52),
                                          size: 28),
                                    ),
                            ),
                            // Info
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(book.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF1B5E35))),
                                    const SizedBox(height: 3),
                                    Text(book.author,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey)),
                                    const SizedBox(height: 3),
                                    Text('ISBN: ${book.isbn}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7D52)
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(book.genre,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF2E7D52),
                                              fontWeight:
                                                  FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Actions
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_right,
                                      color: Colors.grey, size: 20),
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              BookDetailScreen(
                                                  book: book))),
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 18),
                                  onPressed: () =>
                                      _showDeleteDialog(book.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Book',
            style: TextStyle(
                color: Color(0xFF1B5E35),
                fontWeight: FontWeight.bold)),
        content:
            const Text('Are you sure you want to delete this book?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteBook(id);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ============ DASHBOARD HOME ============
  Widget _buildDashboardHome() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? '🌅 Good Morning'
        : hour < 17
            ? '☀️ Good Afternoon'
            : '🌙 Good Evening';

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: const Color(0xFF2E7D52),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E35), Color(0xFF2E7D52)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF2E7D52).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(_userName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(_userEmail,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined,
                                  color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text('Administrator',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: Colors.white, size: 32),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Overview',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E35))),
                GestureDetector(
                  onTap: _loadStats,
                  child: const Row(
                    children: [
                      Icon(Icons.refresh,
                          size: 14, color: Color(0xFF2E7D52)),
                      SizedBox(width: 4),
                      Text('Refresh',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2E7D52),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 4 Stats in 2x2 grid — compact
            Row(
              children: [
                Expanded(
                    child: _compactStatCard(
                        'Total', _totalBooks,
                        Icons.menu_book,
                        const Color(0xFF2E7D52),
                        const Color(0xFFE8F5E9))),
                const SizedBox(width: 10),
                Expanded(
                    child: _compactStatCard(
                        'Available', _totalAvailable,
                        Icons.check_circle_outline,
                        Colors.blue,
                        const Color(0xFFE3F2FD))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _compactStatCard(
                        'Issued', _totalIssued,
                        Icons.book_outlined,
                        Colors.orange,
                        const Color(0xFFFFF3E0))),
                const SizedBox(width: 10),
                Expanded(
                    child: _compactStatCard(
                        'Returned', _totalReturned,
                        Icons.assignment_return,
                        Colors.purple,
                        const Color(0xFFF3E5F5))),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Actions
            const Text('Quick Actions',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E35))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _quickAction(
                        'All Books',
                        Icons.menu_book,
                        const Color(0xFF2E7D52),
                        () => setState(() => _selectedIndex = 1))),
                const SizedBox(width: 10),
                Expanded(
                    child: _quickAction(
                        'Issue Book',
                        Icons.send,
                        Colors.orange,
                        () => setState(() => _selectedIndex = 3))),
                const SizedBox(width: 10),
                Expanded(
                    child: _quickAction(
                        'Categories',
                        Icons.category,
                        Colors.blue,
                        () => setState(() => _selectedIndex = 2))),
                const SizedBox(width: 10),
                Expanded(
                    child: _quickAction(
                        'Analytics',
                        Icons.bar_chart,
                        Colors.purple,
                        () => setState(() => _selectedIndex = 5))),
              ],
            ),
            const SizedBox(height: 20),

            // Recent Issues
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Issues',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E35))),
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 3),
                  child: const Text('View All',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E7D52),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _recentIssues.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 40,
                            color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(height: 8),
                        const Text('No recent issues',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  )
                : Column(
                    children: _recentIssues
                        .map((issue) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7D52)
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.book,
                                        color: Color(0xFF2E7D52),
                                        size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(issue.bookTitle,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                                fontSize: 13)),
                                        Text(
                                            '${issue.userName} • Return: ${issue.returnDate}',
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: issue.isReturned
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.orange
                                              .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      issue.isReturned
                                          ? 'Returned'
                                          : 'Active',
                                      style: TextStyle(
                                          color: issue.isReturned
                                              ? Colors.green
                                              : Colors.orange,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _compactStatCard(String title, int value, IconData icon,
      Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value.toString(),
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(title,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction(String label, IconData icon, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D52),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded,
                color: Colors.white, size: 26),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(_pageTitles[_selectedIndex],
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Colors.white, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: Colors.white, size: 22),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _getPage(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E35), Color(0xFF2E7D52)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1B5E35)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        size: 30, color: Color(0xFF2E7D52)),
                  ),
                  const SizedBox(height: 8),
                  Text(_userName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text(_userEmail,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 6, top: 4),
              child: Text('MENU',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
            ),
            _drawerItem(0, Icons.dashboard_rounded, 'Dashboard'),
            _drawerItem(1, Icons.menu_book_rounded, 'All Books'),
            _drawerItem(2, Icons.category_rounded, 'Categories'),
            _drawerItem(3, Icons.book_outlined, 'Issue Management'),
            _drawerItem(4, Icons.admin_panel_settings_rounded, 'Admin Panel'),
            _drawerItem(5, Icons.bar_chart_rounded, 'Analytics'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(color: Colors.white24),
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded,
                  color: Colors.white54, size: 20),
              title: const Text('Logout',
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
              onTap: _logout,
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('Library Management v1.0',
                  style: TextStyle(color: Colors.white24, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon,
            color: isSelected ? Colors.white : Colors.white60, size: 20),
        title: Text(title,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14)),
        onTap: () {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }
}