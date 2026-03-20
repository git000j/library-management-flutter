class IssueModel {
  String id;
  String bookId;
  String bookTitle;
  String userName;
  String userEmail;
  String userPhone;
  String issueDate;
  String returnDate;
  bool isReturned;

  IssueModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.issueDate,
    required this.returnDate,
    this.isReturned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'issueDate': issueDate,
      'returnDate': returnDate,
      'isReturned': isReturned,
    };
  }

  factory IssueModel.fromMap(Map<String, dynamic> map) {
    return IssueModel(
      id: map['id'] ?? '',
      bookId: map['bookId'] ?? '',
      bookTitle: map['bookTitle'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userPhone: map['userPhone'] ?? '',
      issueDate: map['issueDate'] ?? '',
      returnDate: map['returnDate'] ?? '',
      isReturned: map['isReturned'] ?? false,
    );
  }
}
