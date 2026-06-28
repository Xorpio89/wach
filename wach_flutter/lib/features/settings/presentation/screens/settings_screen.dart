import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../exercise/presentation/providers/exercise_providers.dart';
import '../../data/settings_provider.dart';
import '../../data/sync_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _factoryReset(BuildContext context, WidgetRef ref) async {
    // First confirmation
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Factory Reset'),
        content: const Text(
          'This will delete ALL your data including exercises and sessions. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (firstConfirm != true || !context.mounted) return;

    // Second confirmation
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Are you absolutely sure?'),
        content: const Text(
          'All exercises, sessions, and settings will be permanently deleted. '
          'Type "RESET" to confirm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('DELETE EVERYTHING'),
          ),
        ],
      ),
    );

    if (secondConfirm != true || !context.mounted) return;

    // Perform reset
    try {
      final dbService = ref.read(databaseServiceProvider);
      await dbService.clearAllData();

      // Invalidate providers to refresh UI
      ref.invalidate(exercisesProvider);
      ref.invalidate(exercisesStreamProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data has been deleted'),
            backgroundColor: AppColors.error,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openFeedback(BuildContext context) async {
    const url = AppConstants.feedbackUrl;
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback-Link ist noch nicht hinterlegt'),
        ),
      );
      return;
    }
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konnte Feedback-Formular nicht öffnen')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        children: [
          // App Info Section
          _SectionHeader(title: 'App'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: AppConstants.appName,
            subtitle: AppConstants.appFullName,
            trailing: Text(
              'v${AppConstants.appVersion}'
              '${AppConstants.isBeta ? ' · BETA' : ''}',
              style: AppTypography.bodySmall,
            ),
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // Beta / Feedback Section
          _SectionHeader(title: 'Beta'),
          _SettingsTile(
            icon: Icons.science_outlined,
            iconColor: AppColors.secondary,
            title: 'Beta-Version',
            subtitle: 'Diese App ist in Entwicklung — Feedback willkommen!',
          ),
          _SettingsTile(
            icon: Icons.feedback_outlined,
            iconColor: AppColors.primary,
            title: 'Feedback geben',
            subtitle: 'Bug melden oder Idee teilen',
            trailing: const Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            onTap: () => _openFeedback(context),
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // Workout Settings
          _SectionHeader(title: 'Workout'),
          const _AutoStartTimerSetting(),

          const SizedBox(height: AppConstants.spacingLg),

          // Quick Add Chips Section
          _SectionHeader(title: 'Quick Add Chips'),
          _QuickChipsSettings(),

          const SizedBox(height: AppConstants.spacingLg),

          // Cloud Sync Section
          _SectionHeader(title: 'Cloud Sync'),
          const _CloudSyncSettings(),

          const SizedBox(height: AppConstants.spacingLg),

          // Danger Zone
          _SectionHeader(title: 'Danger Zone', color: AppColors.error),
          _SettingsTile(
            icon: Icons.warning_rounded,
            iconColor: AppColors.error,
            title: 'Factory Reset',
            subtitle: 'Delete all data and start fresh',
            titleColor: AppColors.error,
            onTap: () => _factoryReset(context, ref),
          ),

          const SizedBox(height: AppConstants.spacingXl),

          // Footer
          Center(
            child: Text(
              'Made with determination',
              style: AppTypography.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;

  const _SectionHeader({required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppConstants.spacingSm,
        bottom: AppConstants.spacingSm,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: color ?? AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? AppColors.textSecondary,
        ),
        title: Text(
          title,
          style: AppTypography.bodyLarge.copyWith(
            color: titleColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall,
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

class _AutoStartTimerSetting extends ConsumerWidget {
  const _AutoStartTimerSetting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(workoutSettingsProvider);

    return settingsAsync.when(
      data: (settings) => _SettingsTile(
        icon: Icons.timer_rounded,
        title: 'Auto-start Timer',
        subtitle: 'Start timer on first rep',
        trailing: Switch(
          value: settings.autoStartTimerOnFirstRep,
          onChanged: (value) {
            ref.read(workoutSettingsProvider.notifier).setAutoStartTimer(value);
          },
          activeTrackColor: AppColors.primary.withOpacity(0.5),
        ),
      ),
      loading: () => const _SettingsTile(
        icon: Icons.timer_rounded,
        title: 'Auto-start Timer',
        subtitle: 'Loading...',
      ),
      error: (_, __) => const _SettingsTile(
        icon: Icons.timer_rounded,
        title: 'Auto-start Timer',
        subtitle: 'Error loading setting',
      ),
    );
  }
}

class _QuickChipsSettings extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(quickChipSettingsProvider);

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select exercises for quick add',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          settingsAsync.when(
            data: (settings) {
              return Wrap(
                spacing: AppConstants.spacingSm,
                runSpacing: AppConstants.spacingSm,
                children: allQuickChipExercises.map((exercise) {
                  final isEnabled = settings.enabledChips.contains(exercise.name);
                  return FilterChip(
                    avatar: Icon(
                      exercise.icon,
                      size: 16,
                      color: isEnabled ? AppColors.primary : AppColors.textSecondary,
                    ),
                    label: Text(
                      exercise.name,
                      style: AppTypography.labelSmall.copyWith(
                        color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    selected: isEnabled,
                    onSelected: (_) {
                      ref.read(quickChipSettingsProvider.notifier).toggleChip(exercise.name);
                    },
                    backgroundColor: AppColors.background,
                    selectedColor: AppColors.primary.withOpacity( 0.2),
                    checkmarkColor: AppColors.primary,
                    side: BorderSide(
                      color: isEnabled
                          ? AppColors.primary.withOpacity( 0.5)
                          : AppColors.surfaceVariant,
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Error loading settings'),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  ref.read(quickChipSettingsProvider.notifier).resetToDefaults();
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CloudSyncSettings extends ConsumerWidget {
  const _CloudSyncSettings();

  Future<void> _showRestoreDialog(BuildContext context, WidgetRef ref) async {
    final syncState = ref.read(syncProvider);
    if (!syncState.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable sync first')),
      );
      return;
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Restore from Cloud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (syncState.backupInfo?.lastModified != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
                child: Text(
                  'Last backup: ${DateFormat('dd.MM.yyyy HH:mm').format(syncState.backupInfo!.lastModified!)}',
                  style: AppTypography.bodySmall,
                ),
              ),
            const Text('How would you like to restore?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('merge'),
            child: const Text('Merge'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('replace'),
            style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
            child: const Text('Replace All'),
          ),
        ],
      ),
    );

    if (choice == null || !context.mounted) return;

    if (choice == 'replace') {
      // Confirm replace
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Replace all local data?'),
          content: const Text(
            'This will delete all local sessions and replace them with cloud data. '
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (confirm != true || !context.mounted) return;
    }

    final result = await ref.read(syncProvider.notifier).restoreFromCloud(
          merge: choice == 'merge',
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? result.error ?? 'Unknown result'),
          backgroundColor: result.success ? AppColors.primary : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auto-sync toggle
          Row(
            children: [
              Icon(
                Icons.cloud_sync_rounded,
                color: syncState.isEnabled
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Sync to Google Drive',
                      style: AppTypography.bodyLarge,
                    ),
                    Text(
                      syncState.isSignedIn
                          ? syncState.userEmail ?? 'Signed in'
                          : 'Sync sessions to cloud',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              if (syncState.isSyncing)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch(
                  value: syncState.isEnabled,
                  onChanged: (value) async {
                    if (value) {
                      await ref.read(syncProvider.notifier).enableSync();
                    } else {
                      await ref.read(syncProvider.notifier).disableSync();
                    }
                  },
                  activeTrackColor: AppColors.primary.withOpacity(0.5),
                ),
            ],
          ),

          // Show sync info when enabled
          if (syncState.isEnabled) ...[
            const SizedBox(height: AppConstants.spacingMd),
            const Divider(color: AppColors.surfaceVariant),
            const SizedBox(height: AppConstants.spacingSm),

            // Last sync time
            if (syncState.lastSyncTime != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Text(
                      'Last sync: ${DateFormat('dd.MM.yyyy HH:mm').format(syncState.lastSyncTime!)}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),

            // Backup info
            if (syncState.backupInfo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_done_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Text(
                      'Backup size: ${syncState.backupInfo!.formattedSize}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: syncState.isSyncing
                      ? null
                      : () => _showRestoreDialog(context, ref),
                  icon: const Icon(Icons.cloud_download_rounded, size: 18),
                  label: const Text('Restore'),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                TextButton.icon(
                  onPressed: syncState.isSyncing
                      ? null
                      : () => ref.read(syncProvider.notifier).syncNow(),
                  icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: const Text('Sync Now'),
                ),
              ],
            ),
          ],

          // Error message
          if (syncState.error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppConstants.spacingSm),
              child: Text(
                syncState.error!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
