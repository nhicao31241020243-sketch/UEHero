import 'package:flutter/material.dart';

class EventPoster extends StatelessWidget {
	final String? imagePath;
	final BorderRadius borderRadius;
	final IconData placeholderIcon;

	const EventPoster({
		super.key,
		required this.imagePath,
		this.borderRadius = const BorderRadius.all(Radius.circular(14)),
		this.placeholderIcon = Icons.image_outlined,
	});

	@override
	Widget build(BuildContext context) {
		if (imagePath != null && imagePath!.isNotEmpty) {
			return ClipRRect(
				borderRadius: borderRadius,
				child: Image.asset(
					imagePath!,
					fit: BoxFit.cover,
					width: double.infinity,
					height: double.infinity,
					errorBuilder: (context, error, stackTrace) => _placeholder(),
				),
			);
		}
		return _placeholder();
	}

	Widget _placeholder() {
		return Container(
			decoration: BoxDecoration(
				borderRadius: borderRadius,
				gradient: const LinearGradient(
					begin: Alignment.topLeft,
					end: Alignment.bottomRight,
					colors: [Color(0xFF2A2438), Color(0xFF1F1D2B)],
				),
			),
			alignment: Alignment.center,
			child: Icon(placeholderIcon, color: Colors.white24, size: 28),
		);
	}
}
