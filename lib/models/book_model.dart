class BookModel {
  String id;
  String title;
  String author;
  String isbn;
  String genre;
  String imageBase64;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.genre,
    this.imageBase64 = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'genre': genre,
      'imageBase64': imageBase64,
    };
  }

  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      isbn: map['isbn'] ?? '',
      genre: map['genre'] ?? '',
      imageBase64: map['imageBase64'] ?? '',
    );
  }
}
