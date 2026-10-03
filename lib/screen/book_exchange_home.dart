import 'package:flutter/material.dart';

import '../models/book_model.dart';
import 'add_book_screen.dart';
import 'book_detail_screen.dart';

class BookExchangeHome extends StatefulWidget {
  @override
  _BookExchangeHomeState createState() => _BookExchangeHomeState();
}

class _BookExchangeHomeState extends State<BookExchangeHome> {
  List<BookModel> books = [
    BookModel(
      id: '1',
      title: 'Giáo trình Kinh tế Vi mô UEH',
      description: 'Sách còn mới 90%, đã tô highlight vài chương đầu.',
      price: 45000,
      imageUrl: 'https://via.placeholder.com/150',
      ownerId: 'u1',
      ownerName: 'Nguyễn Văn A',
    ),
    BookModel(
      id: '2',
      title: 'Tài liệu Ôn tập Kinh tế Lượng',
      description: 'Cần trao đổi lấy tài liệu Nguyên lý Kế toán.',
      price: 0,
      isExchangeOnly: true,
      imageUrl: 'https://via.placeholder.com/150',
      ownerId: 'u2',
      ownerName: 'Trần Thị B',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chợ Tài Liệu UEH')),
      body: books.isEmpty
          ? Center(child: Text('Chưa có tài liệu nào được đăng.'))
          : GridView.builder(
              padding: EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookDetailScreen(book: book),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.book,
                              size: 50,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                book.isExchangeOnly
                                    ? "Trao đổi"
                                    : "${book.price.toInt()} VNĐ",
                                style: TextStyle(
                                  color: book.isExchangeOnly
                                      ? Colors.blue
                                      : Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newBook = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddBookScreen()),
          );
          if (newBook != null && newBook is BookModel) {
            setState(() {
              books.add(newBook);
            });
          }
        },
        icon: Icon(Icons.add),
        label: Text('Đăng tin'),
      ),
    );
  }
}
