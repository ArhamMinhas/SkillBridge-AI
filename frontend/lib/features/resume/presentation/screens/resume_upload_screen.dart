import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http_parser/http_parser.dart' show MediaType;

import '../../../../app/config/routes.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../core/shared_widgets/ai_coming_soon.dart';
import '../../../../core/shared_widgets/animated_toast.dart';
import '../../../../core/shared_widgets/custom_button.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';

const _maxResumeBytes = 10 * 1024 * 1024;

class ResumeUploadScreen extends StatefulWidget {
  const ResumeUploadScreen({super.key});

  @override
  State<ResumeUploadScreen> createState() => _ResumeUploadScreenState();
}

class _ResumeUploadScreenState extends State<ResumeUploadScreen> {
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  bool _featurePending = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.size > _maxResumeBytes) {
      if (!mounted) return;
      FeedbackManager.warning(context, 'Resume must be under 10MB');
      return;
    }

    setState(() {
      _selectedFile = file;
      _featurePending = false;
    });
  }

  Future<void> _upload() async {
    final file = _selectedFile;
    if (file == null || file.bytes == null) return;

    setState(() {
      _isUploading = true;
      _featurePending = false;
    });

    try {
      final formData = dio.FormData.fromMap({
        'resume': dio.MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
          contentType: MediaType('application', 'pdf'),
        ),
      });

      final response = await ApiClient.instance
          .post<Map<String, dynamic>>(ApiPaths.analyzeResume, data: formData);

      if (!mounted) return;
      FeedbackManager.success(context, 'Resume analyzed');
      context.push(AppRoutes.resumeResult, extra: response.data);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (isFeaturePending(e.statusCode)) {
        setState(() => _featurePending = true);
      } else {
        FeedbackManager.error(context, e.message);
      }
    } catch (_) {
      if (!mounted) return;
      FeedbackManager.error(context, 'Something went wrong. Please try again');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;

    return Scaffold(
      appBar: AppBar(title: const Text('Resume Analyzer')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ResponsiveCenter(
            child: EntranceFade(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Get your ATS score',
                      style: AppTextStyles.heading1(textColor)),
                  const SizedBox(height: 8),
                  Text(
                    'Upload a PDF resume and our AI will score it against '
                    'applicant tracking systems, then suggest improvements.',
                    style:
                        AppTextStyles.bodyMedium(Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 28),
                  _UploadDropZone(
                    file: _selectedFile,
                    formatSize: _formatSize,
                    onTap: _isUploading ? null : _pickFile,
                    onClear: _isUploading
                        ? null
                        : () => setState(() {
                              _selectedFile = null;
                              _featurePending = false;
                            }),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    label: 'Analyze Resume',
                    icon: Icons.auto_awesome_rounded,
                    isLoading: _isUploading,
                    onPressed:
                        _selectedFile == null || _isUploading ? null : _upload,
                  ),
                  if (_featurePending) ...[
                    const SizedBox(height: 32),
                    AiComingSoon(
                      feature: 'Resume analysis',
                      onRetry: _upload,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadDropZone extends StatefulWidget {
  final PlatformFile? file;
  final String Function(int) formatSize;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _UploadDropZone({
    required this.file,
    required this.formatSize,
    required this.onTap,
    required this.onClear,
  });

  @override
  State<_UploadDropZone> createState() => _UploadDropZoneState();
}

class _UploadDropZoneState extends State<_UploadDropZone>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final muted = Theme.of(context).hintColor;
    final hasFile = widget.file != null;
    final file = widget.file;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: DottedBorderBox(
        color: hasFile ? primary : muted.withOpacity(0.4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: hasFile ? primary.withOpacity(0.06) : null,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _float,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, hasFile ? 0 : -6 * _float.value),
                  child: child,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: FadeTransition(opacity: anim, child: child)),
                      child: Container(
                        key: ValueKey(hasFile),
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasFile
                              ? Icons.picture_as_pdf_rounded
                              : Icons.upload_file_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    if (hasFile)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) =>
                              Transform.scale(scale: value, child: child),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.successDark,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Theme.of(context).cardColor, width: 2),
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                hasFile ? file!.name : 'Tap to select a PDF resume',
                style: AppTextStyles.bodyLarge(
                    Theme.of(context).textTheme.bodyLarge!.color!),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                hasFile
                    ? widget.formatSize(file!.size)
                    : 'PDF only, up to 10MB',
                style: AppTextStyles.caption(muted),
              ),
              if (hasFile) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: widget.onClear,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Remove'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Lightweight dashed-border container (no external package) — draws a
/// dashed rounded rectangle around [child] via [CustomPainter].
class DottedBorderBox extends StatelessWidget {
  final Widget child;
  final Color color;

  const DottedBorderBox({super.key, required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadius.card),
    );

    final path = Path()..addRRect(rrect);
    final dashed = _dashPath(path, dashLength: 6, gapLength: 5);
    canvas.drawPath(dashed, paint);
  }

  Path _dashPath(Path source,
      {required double dashLength, required double gapLength}) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : gapLength;
        if (draw) {
          dest.addPath(
            metric.extractPath(
                distance, (distance + length).clamp(0, metric.length)),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
