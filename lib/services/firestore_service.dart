import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';
import '../models/issue_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =================== BOOKS ===================

  // Add Book
  Future<void> addBook(BookModel book) async {
    await _db.collection('books').doc(book.id).set(book.toMap());
  }

  // Get All Books
  Stream<List<BookModel>> getBooks() {
    return _db
        .collection('books')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Delete Book
  Future<void> deleteBook(String bookId) async {
    await _db.collection('books').doc(bookId).delete();
  }

  // =================== ISSUES ===================

  // Add Issue
  Future<void> addIssue(IssueModel issue) async {
    await _db.collection('issues').doc(issue.id).set(issue.toMap());
  }

  // Get All Issues
  Stream<List<IssueModel>> getIssues() {
    return _db
        .collection('issues')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => IssueModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Mark Book Returned
  Future<void> markReturned(String issueId) async {
    await _db.collection('issues').doc(issueId).update({'isReturned': true});
  }

  // =================== USERS ===================

  // Save User to Firestore
  Future<void> saveUser(
    String uid,
    String name,
    String email,
    String photo,
  ) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'photo': photo,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get All Users
  Stream<List<Map<String, dynamic>>> getUsers() {
    return _db
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // =================== STATS ===================

  // Get Dashboard Stats
  Future<Map<String, int>> getStats() async {
    final books = await _db.collection('books').get();
    final issues = await _db.collection('issues').get();
    final issued = issues.docs
        .where((doc) => doc.data()['isReturned'] == false)
        .length;
    final returned = issues.docs
        .where((doc) => doc.data()['isReturned'] == true)
        .length;

    return {
      'totalBooks': books.docs.length,
      'totalIssued': issued,
      'totalReturned': returned,
      'totalAvailable': books.docs.length - issued,
    };
  }
}
