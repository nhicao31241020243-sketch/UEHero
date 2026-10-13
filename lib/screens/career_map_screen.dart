import 'package:flutter/material.dart';

class CareerMapScreen extends StatelessWidget {
  const CareerMapScreen({this.embedded = false, super.key});

  final bool embedded;
  static const _background = Color(0xFF100E19);
  static const _accent = Color(0xFF90E8FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        leading: embedded
            ? null
            : IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                tooltip: 'Quay lại',
              ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/planets/neptune.png',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const Text(
                'Career Map',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Đang phát triển',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tính năng này sẽ sớm ra mắt. Hãy quay lại sau nhé!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFAAA5B8), fontSize: 14),
              ),
              if (!embedded) ...[
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: _background,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 13,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Quay lại',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
