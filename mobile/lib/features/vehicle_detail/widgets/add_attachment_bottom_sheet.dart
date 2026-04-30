import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/attachment_model.dart';
import '../providers/attachments_provider.dart';

class AddAttachmentBottomSheet extends ConsumerStatefulWidget {
  const AddAttachmentBottomSheet({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  ConsumerState<AddAttachmentBottomSheet> createState() =>
      _AddAttachmentBottomSheetState();
}

class _AddAttachmentBottomSheetState
    extends ConsumerState<AddAttachmentBottomSheet> {
  AttachmentKind _kind = AttachmentKind.other;
  File? _pickedFile;
  String? _pickedName;
  DateTime? _expiryDate;
  final _notesCtrl = TextEditingController();
  bool _saving = false;
  final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: false,
      withReadStream: false,
    );
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _pickedFile = File(result.files.single.path!);
      _pickedName = result.files.single.name;
    });
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
      helpText: 'Select expiry date',
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _save() async {
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file')),
      );
      return;
    }
    setState(() => _saving = true);
    final success = await ref
        .read(attachmentsProvider(widget.vehicleId).notifier)
        .addAttachment(
          file: _pickedFile!,
          kind: _kind,
          expirationDate: _expiryDate,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
    if (mounted) {
      setState(() => _saving = false);
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title bar ───────────────────────────────────────
          Row(
            children: [
              Text(
                'Add File',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── File picker ─────────────────────────────────────
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _pickedFile != null ? cs.primary : cs.outline,
                  width: _pickedFile != null ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: cs.surface,
              ),
              child: Row(
                children: [
                  Icon(
                    _pickedFile != null
                        ? Icons.check_circle_rounded
                        : Icons.attach_file_rounded,
                    color: _pickedFile != null ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _pickedName ?? 'Tap to select a file (PDF, image)',
                      style: TextStyle(
                        color: _pickedFile != null
                            ? cs.onSurface
                            : cs.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Kind dropdown ────────────────────────────────────
          Text(
            'Document Kind',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<AttachmentKind>(
            initialValue: _kind,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: AttachmentKind.values
                .map(
                  (k) => DropdownMenuItem(
                    value: k,
                    child: Text(k.label),
                  ),
                )
                .toList(),
            onChanged: (k) {
              if (k != null) setState(() => _kind = k);
            },
          ),
          const SizedBox(height: 12),

          // ── Optional expiry date ─────────────────────────────
          InkWell(
            onTap: _pickExpiry,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outline),
                borderRadius: BorderRadius.circular(12),
                color: cs.surface,
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    _expiryDate != null
                        ? 'Expires ${_dateFmt.format(_expiryDate!)}'
                        : 'Expiry date (optional)',
                    style: TextStyle(
                      color: _expiryDate != null
                          ? cs.onSurface
                          : cs.onSurfaceVariant,
                    ),
                  ),
                  if (_expiryDate != null) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _expiryDate = null),
                      child: Icon(Icons.close_rounded,
                          size: 16, color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Notes ────────────────────────────────────────────
          TextFormField(
            controller: _notesCtrl,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'e.g. Issued by Generali',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 2,
            maxLength: 500,
          ),
          const SizedBox(height: 20),

          // ── Save button ─────────────────────────────────────
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Upload'),
          ),
        ],
      ),
    );
  }
}
