// lib/widgets/common.dart
//
// Small reusable building blocks shared by several screens.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../models/category.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../services/image_storage.dart';

/// Card with an emoji + title header.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.emoji,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final String title;
  final String? emoji;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (emoji != null) ...[
                  Text(emoji!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

/// Rounded square with the category emoji.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category, this.size = 42});

  final ExpenseCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: Text(category.emoji, style: TextStyle(fontSize: size * 0.45)),
    );
  }
}

/// Friendly empty state with an illustration from the assets folder.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.image = 'assets/images/empty_wallet.png',
    this.action,
  });

  final String message;
  final String image;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    // Smaller illustration when the screen is short (landscape phones).
    final height = MediaQuery.sizeOf(context).height;
    final imgSize = (height * 0.22).clamp(80.0, 180.0);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(image, width: imgSize, height: imgSize),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 14),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// "< November 2026 >" month switcher bound to ExpenseProvider.
class MonthSelector extends StatelessWidget {
  const MonthSelector({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Previous month',
          icon: Icon(rtl ? Icons.chevron_right : Icons.chevron_left),
          onPressed: provider.previousMonth,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 140),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          icon: Icon(rtl ? Icons.chevron_left : Icons.chevron_right),
          onPressed: provider.canGoNext ? provider.nextMonth : null,
        ),
      ],
    );
  }
}

/// Circular profile picture: picked photo -> asset fallback.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.radius = 24});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final path = context.watch<SettingsProvider>().profileImagePath;
    final ImageProvider image = ImageStorage.exists(path)
        ? FileImage(File(path!))
        : const AssetImage('assets/images/avatar.png');
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.blush,
      backgroundImage: image,
    );
  }
}

/// Shows an image saved on the device, or nothing if it disappeared.
class LocalImage extends StatelessWidget {
  const LocalImage({
    super.key,
    required this.path,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.radius = 16,
  });

  final String? path;
  final double? height;
  final double? width;
  final BoxFit fit;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (!ImageStorage.exists(path)) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.file(
        File(path!),
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

/// Bottom sheet asking camera vs gallery; returns the saved path.
Future<String?> pickImage(BuildContext context, {String prefix = 'img'}) async {
  final s = context.sRead;
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(s.camera),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(s.gallery),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  try {
    return await ImageStorage.pickAndSave(source, prefix: prefix);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
    return null;
  }
}

/// Small pill showing sync state; tapping it triggers a refresh.
class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ExpenseProvider>();
    if (!p.hasBackend) return const SizedBox.shrink();
    final s = context.s;
    IconData icon;
    String tip;
    Color color;
    if (p.isSyncing) {
      icon = Icons.cloud_sync_outlined;
      tip = s.syncing;
      color = AppColors.lilac;
    } else if (p.syncError != null) {
      icon = Icons.cloud_off_outlined;
      tip = s.offline;
      color = AppColors.danger;
    } else if (p.pendingCount > 0) {
      icon = Icons.cloud_upload_outlined;
      tip = s.pendingChanges(p.pendingCount);
      color = Colors.orange;
    } else {
      icon = Icons.cloud_done_outlined;
      tip = s.syncDone;
      color = AppColors.success;
    }
    return IconButton(
      tooltip: tip,
      icon: Icon(icon, color: color),
      onPressed: p.isSyncing ? null : () => p.refresh(),
    );
  }
}
