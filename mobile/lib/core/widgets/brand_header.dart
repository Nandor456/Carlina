import 'package:flutter/material.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.primaryContainer],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Carlina',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
