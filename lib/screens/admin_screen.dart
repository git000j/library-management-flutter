import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/issue_model.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Map<String, dynamic>> _userStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    final issuesJson = prefs.getString('issues_list') ?? '[]';
    final List issuesDecoded = jsonDecode(issuesJson);
    final issues =
        issuesDecoded.map((e) => IssueModel.fromMap(e)).toList();

    // Anti-duplication: group by email
    Map<String, Map<String, dynamic>> userMap = {};

    for (var issue in issues) {
      final key = issue.userEmail.toLowerCase().trim();
      if (!userMap.containsKey(key)) {
        userMap[key] = {
          'name': issue.userName,
          'email': issue.userEmail,
          'phone': issue.userPhone,
          'totalIssued': 0,
          'totalReturned': 0,
          'activeBooks': <String>[],
        };
      }
      userMap[key]!['totalIssued'] =
          (userMap[key]!['totalIssued'] as int) + 1;
      if (issue.isReturned) {
        userMap[key]!['totalReturned'] =
            (userMap[key]!['totalReturned'] as int) + 1;
      } else {
        (userMap[key]!['activeBooks'] as List<String>)
            .add(issue.bookTitle);
      }
    }

    setState(() {
      _userStats = userMap.values.toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(
                color: Color(0xFF2E7D52)))
        : _userStats.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline,
                        size: 80,
                        color: Colors.green.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    const Text('No users found',
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 8),
                    const Text('Issue books to see user data',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey)),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadAdminData,
                child: Column(
                  children: [
                    // Summary Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFF2E7D52),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                        children: [
                          _headerStat('Total Users',
                              _userStats.length.toString(),
                              Icons.people),
                          _headerStat(
                              'Active Issues',
                              _userStats
                                  .fold(
                                      0,
                                      (sum, u) =>
                                          sum +
                                          (u['totalIssued'] as int) -
                                          (u['totalReturned'] as int))
                                  .toString(),
                              Icons.book_outlined),
                          _headerStat(
                              'Returned',
                              _userStats
                                  .fold(
                                      0,
                                      (sum, u) =>
                                          sum +
                                          (u['totalReturned'] as int))
                                  .toString(),
                              Icons.assignment_return),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _userStats.length,
                        itemBuilder: (context, index) {
                          final user = _userStats[index];
                          final active =
                              (user['totalIssued'] as int) -
                                  (user['totalReturned'] as int);
                          final activeBooks = user['activeBooks']
                              as List<String>;

                          return Container(
                            margin:
                                const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.green
                                        .withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: Column(
                              children: [
                                // User Header
                                Container(
                                  padding:
                                      const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D52)
                                        .withOpacity(0.05),
                                    borderRadius:
                                        const BorderRadius.only(
                                      topLeft:
                                          Radius.circular(16),
                                      topRight:
                                          Radius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            const Color(0xFF2E7D52),
                                        child: Text(
                                          user['name']
                                              .toString()
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            Text(
                                              user['name'],
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight:
                                                      FontWeight
                                                          .bold),
                                            ),
                                            Text(
                                              user['email'],
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      Colors.grey),
                                            ),
                                            Text(
                                              user['phone'],
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Stats Row
                                Padding(
                                  padding:
                                      const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                          child: _userStatBox(
                                              'Total Issued',
                                              user['totalIssued']
                                                  .toString(),
                                              Colors.orange)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: _userStatBox(
                                              'Returned',
                                              user['totalReturned']
                                                  .toString(),
                                              Colors.green)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: _userStatBox(
                                              'Active',
                                              active.toString(),
                                              active > 0
                                                  ? Colors.red
                                                  : Colors.grey)),
                                    ],
                                  ),
                                ),
                                // Active Books
                                if (activeBooks.isNotEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(
                                            16, 0, 16, 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                            'Currently Holding:',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.bold,
                                                color: Color(
                                                    0xFF2E7D52))),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: activeBooks
                                              .map((book) =>
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal:
                                                            10,
                                                        vertical:
                                                            4),
                                                    decoration:
                                                        BoxDecoration(
                                                      color: Colors
                                                          .orange
                                                          .withOpacity(
                                                              0.1),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                                  20),
                                                      border: Border.all(
                                                          color: Colors
                                                              .orange
                                                              .withOpacity(
                                                                  0.3)),
                                                    ),
                                                    child: Text(
                                                        book,
                                                        style: const TextStyle(
                                                            fontSize:
                                                                12,
                                                            color: Colors
                                                                .orange)),
                                                  ))
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
  }

  Widget _headerStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _userStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}