import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/family_provider.dart';
import '../../../core/models/family_member_model.dart';
import '../widgets/family_member_card.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(familyProvider.notifier).load());
  }

  Future<void> _showInviteDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Family Member'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Email address',
            hintText: 'Enter their account email',
          ),
          onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      final error =
          await ref.read(familyProvider.notifier).sendInvite(result);
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite sent!')),
        );
      }
    }
  }

  Future<void> _confirmRemove(FamilyMemberModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Family Member'),
        content:
            Text('Remove ${member.displayName} from your family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(familyProvider.notifier).removeMember(member.linkId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(familyProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(familyProvider.notifier).load(),
        child: _buildBody(state, cs),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteDialog,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Member'),
      ),
    );
  }

  Widget _buildBody(FamilyState state, ColorScheme cs) {
    if (state.isLoading &&
        state.members.isEmpty &&
        state.receivedInvites.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: cs.error),
            const SizedBox(height: 8),
            Text(state.error!),
            TextButton(
              onPressed: () => ref.read(familyProvider.notifier).load(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final sections = <Widget>[];

    // ── Pending received invites ──────────────────────────────
    if (state.receivedInvites.isNotEmpty) {
      sections.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Pending Invites',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      );
      for (final invite in state.receivedInvites) {
        sections.add(_InviteCard(
          invite: invite,
          onAccept: () =>
              ref.read(familyProvider.notifier).acceptInvite(invite.linkId),
          onDecline: () =>
              ref.read(familyProvider.notifier).declineInvite(invite.linkId),
        ));
      }
    }

    // ── Sent invites (pending) ────────────────────────────────
    if (state.sentInvites.isNotEmpty) {
      sections.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Sent Invites',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      );
      for (final invite in state.sentInvites) {
        sections.add(_SentInviteCard(invite: invite));
      }
    }

    // ── Accepted members ──────────────────────────────────────
    if (state.members.isNotEmpty) {
      sections.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Family Members',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      );
      for (final member in state.members) {
        sections.add(FamilyMemberCard(
          key: ValueKey(member.id),
          member: member,
          onViewCars: () => context.push('/family/${member.id}',
              extra: member.displayName),
          onRemove: () => _confirmRemove(member),
        ));
      }
    }

    if (sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_outlined, size: 72, color: cs.outline),
            const SizedBox(height: 16),
            Text(
              'No family members yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to invite someone',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    sections.add(const SizedBox(height: 100));

    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: sections,
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.invite,
    required this.onAccept,
    required this.onDecline,
  });

  final FamilyMemberModel invite;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: cs.primaryContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: cs.primaryContainer,
              child: Text(
                invite.displayName[0].toUpperCase(),
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(invite.displayName,
                      style: textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  if (invite.fullName != null)
                    Text(invite.email,
                        style: textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              color: cs.error,
              tooltip: 'Decline',
              onPressed: onDecline,
            ),
            IconButton(
              icon: const Icon(Icons.check_rounded),
              color: cs.primary,
              tooltip: 'Accept',
              onPressed: onAccept,
            ),
          ],
        ),
      ),
    );
  }
}

class _SentInviteCard extends StatelessWidget {
  const _SentInviteCard({required this.invite});
  final FamilyMemberModel invite;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: cs.surfaceContainerHigh,
              child: Text(
                invite.displayName[0].toUpperCase(),
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(invite.displayName,
                      style: textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  if (invite.fullName != null)
                    Text(invite.email,
                        style: textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Chip(
              label: const Text('Pending'),
              labelStyle: TextStyle(
                  fontSize: 11, color: cs.onSurfaceVariant),
              backgroundColor: cs.surfaceContainerHigh,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
