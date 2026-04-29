import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import '../../../core/models/document_model.dart';
import '../../../core/theme/app_theme.dart';

class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.documentType,
    this.document,
    required this.onTap,
  });

  final DocumentType documentType;
  final DocumentModel? document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final doc = document;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFmt = DateFormat('dd MMM yyyy');

    final hasDoc = doc != null;
    final status = hasDoc ? doc.status : null;
    final statusColor = status?.color ?? cs.outline;
    final statusBg = status?.lightColor ?? cs.surfaceContainerLow;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────
              Row(
                children: [
                  // Icon badge
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hasDoc ? (status?.icon ?? Icons.description_outlined) : Icons.add_circle_outline_rounded,
                      color: statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          documentType.label,
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          documentType.description,
                          style: textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  // Status chip or "Add" prompt
                  if (hasDoc)
                    _StatusBadge(status: status!, daysLeft: doc.daysLeft)
                  else
                    TextButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add'),
                    ),
                ],
              ),

              // ── Dates + progress bar (only when doc exists) ─
              if (hasDoc) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DateLabel(
                      label: 'Issued',
                      date: dateFmt.format(doc.issueDate),
                    ),
                    _DateLabel(
                      label: 'Expires',
                      date: dateFmt.format(doc.expirationDate),
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearPercentIndicator(
                  percent: doc.progressFraction,
                  lineHeight: 8,
                  backgroundColor: cs.surfaceContainerHighest,
                  progressColor: statusColor,
                  barRadius: const Radius.circular(8),
                  padding: EdgeInsets.zero,
                  animation: true,
                  animationDuration: 600,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.daysLeft});

  final DocumentStatus status;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final label = switch (daysLeft) {
      < 0 => 'Expired',
      0 => 'Today!',
      1 => '1 day left',
      _ => '$daysLeft days left',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.lightColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: status.color,
        ),
      ),
    );
  }
}

class _DateLabel extends StatelessWidget {
  const _DateLabel({required this.label, required this.date, this.color});

  final String label;
  final String date;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
        Text(
          date,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? cs.onSurface,
          ),
        ),
      ],
    );
  }
}
