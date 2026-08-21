import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/navigation/app_router.dart';
import '../../../exercise/presentation/providers/exercise_providers.dart';
import '../../../feedback/presentation/providers/feedback_providers.dart';
import '../../data/settings_provider.dart';
import '../../data/locale_provider.dart';
import '../../data/sync_provider.dart';
import '../../../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _factoryReset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    // First confirmation
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.settingsFactoryResetTitle),
        content: Text(l10n.settingsFactoryResetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.commonContinue),
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
        title: Text(l10n.settingsFactoryResetConfirmTitle),
        content: Text(l10n.settingsFactoryResetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.settingsFactoryResetConfirmAction),
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
          SnackBar(
            content: Text(l10n.settingsFactoryResetDone),
            backgroundColor: AppColors.error,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.commonError(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final offeneNotizen = ref.watch(offeneFeedbackAnzahlProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(l10n.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        children: [
          // App Info Section
          _SectionHeader(title: l10n.settingsSectionApp),
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
          _SectionHeader(title: l10n.settingsSectionBeta),
          _SettingsTile(
            icon: Icons.science_outlined,
            iconColor: AppColors.secondary,
            title: l10n.settingsBetaTitle,
            subtitle: l10n.settingsBetaSubtitle,
          ),
          _SettingsTile(
            icon: Icons.feedback_outlined,
            iconColor: AppColors.primary,
            title: l10n.settingsFeedbackTitle,
            subtitle: l10n.settingsFeedbackSubtitle,
            // Zeigt an, was notiert, aber noch nicht weitergegeben wurde —
            // sonst bleibt es unbemerkt liegen.
            trailing: offeneNotizen > 0
                ? Text(
                    l10n.feedbackOffeneAnzahl(offeneNotizen),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.secondary,
                    ),
                  )
                : const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
            onTap: () => context.pushNamed(Routes.feedback),
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // Workout Settings
          _SectionHeader(title: l10n.settingsSectionLanguage),
          const _LanguageSetting(),

          const SizedBox(height: AppConstants.spacingLg),

          // Workout Settings
          _SectionHeader(title: l10n.settingsSectionWorkout),
          const _AutoStartTimerSetting(),

          const SizedBox(height: AppConstants.spacingLg),

          // Quick Add Chips Section
          _SectionHeader(title: l10n.settingsSectionQuickChips),
          _QuickChipsSettings(),

          const SizedBox(height: AppConstants.spacingLg),

          // Cloud Sync Section
          _SectionHeader(title: l10n.settingsSectionCloudSync),
          const _CloudSyncSettings(),

          const SizedBox(height: AppConstants.spacingLg),

          // Danger Zone
          _SectionHeader(
            title: l10n.settingsSectionDanger,
            color: AppColors.error,
          ),
          _SettingsTile(
            icon: Icons.warning_rounded,
            iconColor: AppColors.error,
            title: l10n.settingsFactoryResetTitle,
            subtitle: l10n.settingsFactoryResetSubtitle,
            titleColor: AppColors.error,
            onTap: () => _factoryReset(context, ref),
          ),

          const SizedBox(height: AppConstants.spacingXl),

          // Footer
          Center(
            child: Text(
              l10n.settingsFooter,
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
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(workoutSettingsProvider);

    return settingsAsync.when(
      data: (settings) => _SettingsTile(
        icon: Icons.timer_rounded,
        title: l10n.settingsAutoStartTitle,
        subtitle: l10n.settingsAutoStartSubtitle,
        trailing: Switch(
          value: settings.autoStartTimerOnFirstRep,
          onChanged: (value) {
            ref.read(workoutSettingsProvider.notifier).setAutoStartTimer(value);
          },
          activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
      loading: () => _SettingsTile(
        icon: Icons.timer_rounded,
        title: l10n.settingsAutoStartTitle,
        subtitle: l10n.commonLoading,
      ),
      error: (_, __) => _SettingsTile(
        icon: Icons.timer_rounded,
        title: l10n.settingsAutoStartTitle,
        subtitle: l10n.settingsAutoStartError,
      ),
    );
  }
}

class _QuickChipsSettings extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
            l10n.settingsQuickChipsHint,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          settingsAsync.when(
            data: (settings) {
              return Wrap(
                spacing: AppConstants.spacingSm,
                runSpacing: AppConstants.spacingSm,
                children: allQuickChipExercises.map((exercise) {
                  final isEnabled =
                      settings.enabledChips.contains(exercise.name);
                  return FilterChip(
                    avatar: Icon(
                      exercise.icon,
                      size: 16,
                      color: isEnabled
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    label: Text(
                      exercise.name,
                      style: AppTypography.labelSmall.copyWith(
                        color: isEnabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    selected: isEnabled,
                    onSelected: (_) {
                      ref
                          .read(quickChipSettingsProvider.notifier)
                          .toggleChip(exercise.name);
                    },
                    backgroundColor: AppColors.background,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    side: BorderSide(
                      color: isEnabled
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.surfaceVariant,
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(l10n.settingsQuickChipsError),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  ref
                      .read(quickChipSettingsProvider.notifier)
                      .resetToDefaults();
                },
                child: Text(l10n.commonReset),
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
    final l10n = AppLocalizations.of(context);
    final syncState = ref.read(syncProvider);
    if (!syncState.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsSyncEnableFirst)),
      );
      return;
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.settingsRestoreTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (syncState.backupInfo?.lastModified != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
                child: Text(
                  l10n.settingsSyncLastBackup(
                    DateFormat('dd.MM.yyyy HH:mm')
                        .format(syncState.backupInfo!.lastModified!),
                  ),
                  style: AppTypography.bodySmall,
                ),
              ),
            Text(l10n.settingsRestoreQuestion),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('merge'),
            child: Text(l10n.settingsRestoreMerge),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('replace'),
            style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
            child: Text(l10n.settingsRestoreReplaceAll),
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
          title: Text(l10n.settingsRestoreReplaceTitle),
          content: Text(l10n.settingsRestoreReplaceBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(l10n.settingsRestoreReplace),
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
          content: Text(
            result.message ?? result.error ?? l10n.settingsRestoreUnknown,
          ),
          backgroundColor: result.success ? AppColors.primary : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
                      l10n.settingsSyncTitle,
                      style: AppTypography.bodyLarge,
                    ),
                    Text(
                      syncState.isSignedIn
                          ? syncState.userEmail ?? l10n.settingsSyncSignedIn
                          : l10n.settingsSyncSubtitle,
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
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
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
                      l10n.settingsSyncLastSync(
                        DateFormat('dd.MM.yyyy HH:mm')
                            .format(syncState.lastSyncTime!),
                      ),
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
                      l10n.settingsSyncBackupSize(
                        syncState.backupInfo!.formattedSize,
                      ),
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
                  label: Text(l10n.settingsSyncRestore),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                TextButton.icon(
                  onPressed: syncState.isSyncing
                      ? null
                      : () => ref.read(syncProvider.notifier).syncNow(),
                  icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: Text(l10n.settingsSyncNow),
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

/// Sprachumschalter (Deutsch / Englisch).
///
/// Die Sprachnamen stehen bewusst in der jeweiligen Sprache selbst —
/// wer versehentlich die falsche Sprache waehlt, findet den Weg zurueck
/// auch dann, wenn er die aktive Sprache nicht lesen kann.
class _LanguageSetting extends ConsumerWidget {
  const _LanguageSetting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(localeProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.language_rounded, color: AppColors.textSecondary),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.settingsLanguageTitle,
                    style: AppTypography.bodyLarge),
                Text(l10n.settingsLanguageSubtitle,
                    style: AppTypography.bodySmall),
              ],
            ),
          ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'de', label: Text('Deutsch')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {current.languageCode},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              ref
                  .read(localeProvider.notifier)
                  .setLocale(Locale(selection.first));
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textSecondary,
              selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.2),
              selectedForegroundColor: AppColors.primary,
              textStyle: AppTypography.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}
