import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uehero/widgets/interview/answer_pill.dart';
import 'package:uehero/widgets/interview/interview_control_bar.dart';

void main() {
  testWidgets('answer pill and controls fit a 320px viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF100E19),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnswerPill(
                    text: 'Một câu trả lời đủ dài để kiểm tra giao diện nhỏ',
                    onEdit: () {},
                    onSend: () {},
                    enabled: true,
                  ),
                  const SizedBox(height: 12),
                  InterviewControlBar(
                    onHint: () {},
                    onKeyboard: () {},
                    onSkip: () {},
                    onEnd: () {},
                    enabled: true,
                    hintsRemaining: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Một câu trả lời'), findsOneWidget);
  });
}
