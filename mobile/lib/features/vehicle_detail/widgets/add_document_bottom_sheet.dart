import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/document_model.dart';
import '../providers/documents_provider.dart';

class AddDocumentBottomSheet extends ConsumerStatefulWidget {
  const AddDocumentBottomSheet({
    super.key,
    required this.vehicleId,
    this.existingDocument,
    this.preselectedType,
  });

  final String vehicleId;
  final DocumentModel? existingDocument;
  final DocumentType? preselectedType;

  @override
  ConsumerState<AddDocumentBottomSheet> createState() =>
      _AddDocumentBottomSheetState();
}

class _AddDocumentBottomSheetState
    extends ConsumerState<AddDocumentBottomSheet> {
  late DocumentType _selectedType;
  DateTime? _issueDate;
  DateTime? _expiryDate;
  bool _saving = false;
  final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    final doc = widget.existingDocument;
    _selectedType = doc?.documentType ??
        widget.preselectedType ??
        DocumentType.rca;
    _issueDate = doc?.issueDate;
    _expiryDate = doc?.expirationDate;
  }

  Future<void> _pickDate({required bool isExpiry}) async {
    final initial = (isExpiry ? _expiryDate : _issueDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
      helpText: isExpiry ? 'Select expiry date' : 'Select issue date',
    );
    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _issueDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_issueDate == null || _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both dates')),
      );
      return;
    }
    if (_expiryDate!.isBefore(_issueDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expiry must be after issue date')),
      );
      return;
    }

    setState(() => _saving = true);
    final notifier = ref.read(documentsProvider(widget.vehicleId).notifier);

    bool success;
    if (widget.existingDocument != null) {
      success = await notifier.updateDocument(
        widget.existingDocument!.id,
        issueDate: _issueDate!,
        expirationDate: _expiryDate!,
      );
    } else {
      success = await notifier.addDocument(
        documentType: _selectedType,
        issueDate: _issueDate!,
        expirationDate: _expiryDate!,
      );
    }

    if (mounted) {
      setState(() => _saving = false);
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.existingDocument != null;

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
                isEditing ? 'Edit Document' : 'Add Document',
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
          const SizedBox(height: 20),

          // ── Document type selector (disabled when editing) ──
          Text('Document Type',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          SegmentedButton<DocumentType>(
            segments: DocumentType.values
                .map(
                  (t) => ButtonSegment(
                    value: t,
                    label: Text(t.label),
                    icon: const Icon(Icons.description_outlined),
                  ),
                )
                .toList(),
            selected: {_selectedType},
            onSelectionChanged: isEditing
                ? null
                : (s) => setState(() => _selectedType = s.first),
          ),
          const SizedBox(height: 20),

          // ── Date pickers ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _DatePickerTile(
                  label: 'Issue Date',
                  date: _issueDate,
                  dateFmt: _dateFmt,
                  onTap: () => _pickDate(isExpiry: false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatePickerTile(
                  label: 'Expiry Date',
                  date: _expiryDate,
                  dateFmt: _dateFmt,
                  onTap: () => _pickDate(isExpiry: true),
                  isExpiry: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

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
                : Text(isEditing ? 'Update Document' : 'Save Document'),
          ),
        ],
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.dateFmt,
    required this.onTap,
    this.isExpiry = false,
  });

  final String label;
  final DateTime? date;
  final DateFormat dateFmt;
  final VoidCallback onTap;
  final bool isExpiry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(12),
          color: cs.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 14, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  date != null ? dateFmt.format(date!) : 'Select',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: date != null ? cs.onSurface : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
