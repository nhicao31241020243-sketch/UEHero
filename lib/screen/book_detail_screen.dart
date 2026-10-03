import 'package:flutter/material.dart';

import '../models/book_model.dart';

class BookDetailScreen extends StatelessWidget {
  final BookModel book;

  BookDetailScreen({required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chi tiết tài liệu')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 280,
                    color: Colors.grey[300],
                    child: Image.network(
                      book.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.book, size: 80, color: Colors.grey[600]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          book.isExchangeOnly
                              ? "🔄 Chỉ trao đổi"
                              : "💰 ${book.price} VNĐ",
                          style: TextStyle(
                            fontSize: 18,
                            color: book.isExchangeOnly
                                ? Colors.blue
                                : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Divider(height: 30),
                        Row(
                          children: [
                            CircleAvatar(child: Icon(Icons.person)),
                            SizedBox(width: 10),
                            Text(
                              "Người đăng: ",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            Text(
                              book.ownerName,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Mô tả:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          book.description,
                          style: TextStyle(fontSize: 15, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.chat),
              label: Text('LIÊN HỆ NGƯỜI BÁN'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đang mở liên hệ với ${book.ownerName}...'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
