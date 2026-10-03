import 'package:flutter/material.dart';

import 'models/event_item.dart';
import 'services/points_manager.dart';
import 'widgets/event_poster.dart';

class EventDetailScreen extends StatefulWidget {
  final EventItem event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final joined = PointsManager.instance.hasJoined(widget.event.title);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0C13),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF0D0C13),
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  EventPoster(
                    imagePath: widget.event.image,
                    borderRadius: BorderRadius.zero,
                    placeholderIcon: Icons.event,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.85),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.event.organizer,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF8B5CF6)),
                    ),
                    child: Text(
                      '+${widget.event.trainingPoints} điểm rèn luyện',
                      style: const TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.event.description.isNotEmpty
                        ? widget.event.description
                        : 'Tham gia sự kiện này để tích lũy điểm rèn luyện cho học kỳ. Điểm sẽ được cộng ngay khi bạn xác nhận tham gia.',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: joined
                          ? null
                          : () {
                              setState(() {
                                PointsManager.instance.joinEvent(widget.event);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Đã cộng +${widget.event.trainingPoints} điểm rèn luyện 🎉',
                                  ),
                                  backgroundColor: const Color(0xFF8B5CF6),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: joined
                            ? Colors.grey[700]
                            : const Color(0xFF8B5CF6),
                        disabledBackgroundColor: Colors.grey[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        joined ? 'Đã tham gia' : 'Xác nhận tham gia',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
