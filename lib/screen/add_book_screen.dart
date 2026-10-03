import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/book_model.dart';

class AddBookScreen extends StatefulWidget {
  @override
  _AddBookScreenState createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isExchangeOnly = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newBook = BookModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descController.text,
        price: _isExchangeOnly
            ? 0
            : (double.tryParse(_priceController.text) ?? 0),
        isExchangeOnly: _isExchangeOnly,
        imageUrl: _selectedImage?.path ?? 'https://via.placeholder.com/150',
        ownerId: 'user_demo',
        ownerName: 'Sinh viên UEH',
      );

      Navigator.pop(context, newBook);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đăng tin sách / tài liệu')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey[600],
                            ),
                            SizedBox(height: 8),
                            Text('Tải ảnh tài liệu'),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Tên sách / Tài liệu',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Vui lòng nhập tên sách'
                    : null,
              ),
              SizedBox(height: 12),
              SwitchListTile(
                title: Text('Chỉ muốn trao đổi (không bán)'),
                value: _isExchangeOnly,
                onChanged: (val) => setState(() => _isExchangeOnly = val),
              ),
              if (!_isExchangeOnly) ...[
                SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Giá bán (VNĐ)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (!_isExchangeOnly && (val == null || val.isEmpty))
                      return 'Vui lòng nhập giá';
                    return null;
                  },
                ),
              ],
              SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Mô tả tình trạng sách',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Vui lòng nhập mô tả' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('ĐĂNG TIN', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
