import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/models/attachment_model.dart';
import '../../auth/providers/auth_provider.dart';

class AttachmentCard extends ConsumerStatefulWidget {
  const AttachmentCard({
    super.key,
    required this.attachment,
  });

  final AttachmentModel attachment;

  @override
  ConsumerState<AttachmentCard> createState() => _AttachmentCardState();
}

class _AttachmentCardState extends ConsumerState<AttachmentCard> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final api = ref.read(apiServiceProvider);
      final bytes = await api.downloadAttachment(
        widget.attachment.vehicleId,
        widget.attachment.id,
      );

      final tmpDir = await getTemporaryDirectory();
      final file = File('${tmpDir.path}/${widget.attachment.originalFilename}');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file')),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attachment;
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd MMM yyyy');

    final expiring = a.expirationDate != null &&
        a.expirationDate!.difference(DateTime.now()).inDays <= 30;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── File type icon ─────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  a.isPdf
                      ? Icons.picture_as_pdf_rounded
                      : Icons.image_rounded,
                  color: a.isPdf ? Colors.red : cs.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),

              // ── Metadata ───────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.originalFilename,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          a.kind.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          ' • ${a.sizeLabel}',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (a.expirationDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.event_rounded,
                            size: 12,
                            color: expiring ? cs.error : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Expires ${dateFmt.format(a.expirationDate!)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: expiring ? cs.error : cs.onSurfaceVariant,
                              fontWeight: expiring ? FontWeight.w600 : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ── Open indicator ─────────────────────────────
              if (_opening)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.open_in_new_rounded, size: 18, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}
