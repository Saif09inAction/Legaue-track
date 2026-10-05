import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:league_track/core/theme/app_spacing.dart';
import 'package:league_track/core/theme/league_track_colors.dart';
import 'package:league_track/core/utils/date_formatters.dart';
import 'package:league_track/providers/cache_providers.dart';

/// Small line under the title: last update, and offline when the cache is in use.
class CacheStatusBanner extends ConsumerWidget {
  const CacheStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notice = ref.watch(cacheNoticeProvider);
    final updatedAt = notice.updatedAt;
    if (updatedAt == null) {
      return const SizedBox.shrink();
    }

    final colors =
        Theme.of(context).extension<LeagueTrackColors>() ??
        LeagueTrackColors.light;
    final theme = Theme.of(context);
    final updated = DateFormatters.formatUpdated(updatedAt);
    final label = notice.offline
        ? 'Offline · Updated $updated'
        : notice.stale
        ? 'Saved data · Updated $updated'
        : 'Updated $updated';

    return Padding(
      key: const Key('cache-status'),
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            notice.offline || notice.stale
                ? Icons.cloud_off_outlined
                : Icons.schedule,
            size: 14,
            color: colors.muted,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(color: colors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
