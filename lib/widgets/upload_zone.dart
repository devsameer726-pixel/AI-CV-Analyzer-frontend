import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import 'glass_container.dart';

/// Drag & drop / tap-to-upload card for PDF/DOCX resume files.
///
/// Emits the selected file bytes + name via [onFileSelected]. Shows a live
/// preview card with metadata and an upload status bar when a file is present.
class UploadZone extends StatefulWidget {
  const UploadZone({
    super.key,
    required this.onFileSelected,
    this.selectedFileName,
    this.selectedFileSize,
    this.status = UploadStatus.idle,
  });

  final ValueChanged<({Uint8List bytes, String name})> onFileSelected;
  final String? selectedFileName;
  final int? selectedFileSize;
  final UploadStatus status;

  @override
  State<UploadZone> createState() => _UploadZoneState();
}

enum UploadStatus { idle, selected, uploading, done, error }

class _UploadZoneState extends State<UploadZone> {
  bool _hovering = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc', 'txt'],
    );
    if (result != null && result.files.single.bytes != null) {
      widget.onFileSelected(
        (
          bytes: result.files.single.bytes!,
          name: result.files.single.name,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.selectedFileName != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drop zone
        MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: _pickFile,
            child: AnimatedContainer(
              duration: 250.ms,
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _hovering
                      ? AppColors.accent
                      : AppColors.accent.withValues(alpha: 0.4),
                  width: _hovering ? 2 : 1.5,
                ),
                boxShadow: _hovering
                    ? [
                        BoxShadow(
                          color: AppColors.accentGlow,
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload_rounded,
                    size: 48,
                    color: _hovering ? AppColors.accent : AppColors.textSecondary,
                  )
                      .animate(autoPlay: true, onPlay: (c) => c.repeat())
                      .shimmer(
                        duration: 1800.ms,
                        color: AppColors.accent.withValues(alpha: 0.4),
                      )
                      .moveY(begin: -3, end: 3, duration: 1800.ms),
                  const SizedBox(height: 12),
                  Text(
                    'Drag & drop your resume',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'or tap to browse — PDF, DOCX, DOC, TXT',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  _DashedBorder(
                    glowing: _hovering,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      child: Text(
                        'Choose File',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // File preview
        if (hasFile) ...[
          const SizedBox(height: 16),
          _FilePreview(
            name: widget.selectedFileName!,
            size: widget.selectedFileSize,
            status: widget.status,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        ],
      ],
    );
  }
}

class _DashedBorder extends StatelessWidget {
  const _DashedBorder({required this.child, this.glowing = false});

  final Widget child;
  final bool glowing;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(glowing: glowing),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({this.glowing = false});

  final bool glowing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = glowing ? AppColors.accent : AppColors.accent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = glowing ? 1.8 : 1.2;
    const dashWidth = 8.0;
    const dashSpace = 5.0;
    final rRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    final path = Path()..addRRect(rRect);
    final metrics = path.computeMetrics().first;
    double distance = 0;
    while (distance < metrics.length) {
      canvas.drawPath(
        metrics.extractPath(distance, distance + dashWidth),
        paint,
      );
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => glowing != old.glowing;
}

class _FilePreview extends StatelessWidget {
  const _FilePreview({
    required this.name,
    required this.size,
    required this.status,
  });

  final String name;
  final int? size;
  final UploadStatus status;

  String get _ext => name.split('.').last.toUpperCase();

  String get _sizeStr {
    if (size == null) return '';
    const units = ['B', 'KB', 'MB'];
    var s = size!.toDouble();
    var u = 0;
    while (s >= 1024 && u < units.length - 1) {
      s /= 1024;
      u++;
    }
    return '${s.toStringAsFixed(s < 10 && u > 0 ? 1 : 0)} ${units[u]}';
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            child: Text(
              _ext,
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _sizeStr.isEmpty ? 'Ready' : _sizeStr,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                _StatusChip(status: status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final UploadStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, progress) = switch (status) {
      UploadStatus.idle => ('Idle', AppColors.textMuted, 0.0),
      UploadStatus.selected => ('Selected', AppColors.accent, 0.3),
      UploadStatus.uploading => ('Uploading…', AppColors.warning, 0.7),
      UploadStatus.done => ('Uploaded', AppColors.success, 1.0),
      UploadStatus.error => ('Failed', AppColors.error, 0.0),
    };
    return Row(
      children: [
        SizedBox(
          width: 120,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.bgElevated,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Helper to read file bytes on non-web platforms where FilePicker returns a path.
Future<Uint8List> readPathBytes(String path) => File(path).readAsBytes();
