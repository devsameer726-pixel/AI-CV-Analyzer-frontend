import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:typed_data';
import '../models/analysis_result.dart';
import '../services/cv_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_score_card.dart';
import '../widgets/glass_container.dart';
import '../widgets/upload_zone.dart';

/// Responsive home screen: glassmorphic header + a two-pane layout on desktop
/// (upload left, dashboard right) collapsing to a single scrollable column on
/// mobile. State is held locally with [StatefulWidget].
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

/// Analysis state machine.
enum AnalysisState { noCv, analyzing, success, error, incomplete }

class _HomeDashboardState extends State<HomeDashboard> {
  final CvApiService _service = CvApiService();

  Uint8List? _fileBytes;
  String? _fileName;
  int? _fileSize;
  UploadStatus _uploadStatus = UploadStatus.idle;

  final TextEditingController _jdController = TextEditingController();

  AnalysisState _state = AnalysisState.noCv;
  AnalysisResult? _result;
  String? _errorMessage;

  @override
  void dispose() {
    _jdController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------
  void _onFileSelected({required Uint8List bytes, required String name}) {
    setState(() {
      // Clear any previous analysis so stale results never bleed into the new
      // CV's results.
      _fileBytes = bytes;
      _fileName = name;
      _fileSize = bytes.lengthInBytes;
      _uploadStatus = UploadStatus.selected;
      _result = null;
      _errorMessage = null;
      _state = AnalysisState.noCv;
    });
  }

  Future<void> _onAnalyze() async {
    if (_fileBytes == null) {
      setState(() => _errorMessage = 'Please upload your CV first.');
      return;
    }

    setState(() {
      _state = AnalysisState.analyzing;
      _errorMessage = null;
      _uploadStatus = UploadStatus.uploading;
    });

    await _runAnalysis();
  }

  Future<void> _retryAnalysis() async {
    setState(() {
      _state = AnalysisState.analyzing;
      _errorMessage = null;
      _uploadStatus = UploadStatus.uploading;
    });
    await _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    try {
      final result = await _service.analyze(
        fileBytes: _fileBytes!,
        fileName: _fileName!,
        jobDescription: _jdController.text,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _state =
            result.hasData ? AnalysisState.success : AnalysisState.incomplete;
        _uploadStatus = UploadStatus.done;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _state = AnalysisState.error;
        _uploadStatus = UploadStatus.error;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgDeep, AppColors.bgMid],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _AppHeader(isDesktop: isDesktop),
              Expanded(
                child: isDesktop
                    ? _DesktopLayout(
                        uploadPanel: _buildUploadPanel(),
                        dashboard: _buildDashboard(isDesktop: true),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildUploadPanel(),
                            const SizedBox(height: 20),
                            _buildDashboard(isDesktop: false),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
  Widget _AppHeader({required bool isDesktop}) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              _Logo(),
              const SizedBox(width: 16),
              if (isDesktop) ..._navLinks(),
              const Spacer(),
              _ThemeToggle(),
              const SizedBox(width: 10),
              _Avatar(),
            ],
          ),
        ),
      );

  List<Widget> _navLinks() => [
        _NavLink(label: 'Dashboard', active: true),
        _NavLink(label: 'ATS Scanner'),
        _NavLink(label: 'Skill Gap'),
        _NavLink(label: 'Settings'),
      ];

  // ---------------------------------------------------------------------------
  // Upload panel (left pane on desktop)
  // ---------------------------------------------------------------------------
  Widget _buildUploadPanel() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Upload & Analyze',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Drop your resume and paste the job description to get an instant '
            'ATS match score with AI recommendations.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          UploadZone(
            onFileSelected: (f) =>
                _onFileSelected(bytes: f.bytes, name: f.name),
            selectedFileName: _fileName,
            selectedFileSize: _fileSize,
            status: _uploadStatus,
          ),
          const SizedBox(height: 20),
          Text('Job Description',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _jdController,
            maxLines: 6,
            minLines: 4,
            style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
            decoration: const InputDecoration(
              hintText: 'Paste the target job description here…\n\n'
                  'e.g. Senior ML Engineer — Python, TensorFlow, AWS, Docker…',
              hintStyle: TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
          ),
          const SizedBox(height: 18),
          _AnalyzeButton(
            onTap: _onAnalyze,
            loading: _state == AnalysisState.analyzing,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ).animate().shake(duration: 500.ms),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dashboard (right pane on desktop)
  // ---------------------------------------------------------------------------
  Widget _buildDashboard({required bool isDesktop}) {
    switch (_state) {
      case AnalysisState.analyzing:
        return const Center(child: _LoadingIndicator());
      case AnalysisState.error:
        return _ErrorState(onRetry: _retryAnalysis);
      case AnalysisState.incomplete:
        return const _IncompleteState();
      case AnalysisState.noCv:
        return const _NoCvState();
      case AnalysisState.success:
        final r = _result!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Hero score
            GlassContainer.neon(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (r.atsScore != null)
                    AnimatedScoreCard(score: r.atsScore!)
                  else
                    const _ScoreUnavailable(),
                  const SizedBox(height: 16),
                  if (r.predictedCategory.isNotEmpty)
                    _CategoryBadge(category: r.predictedCategory)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1)
                  else
                    const _RoleUnavailable().animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 12),
                  if (r.summary.isNotEmpty)
                    Text(
                      r.summary,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ).animate().fadeIn(duration: 500.ms),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),
            if (r.metrics.isNotEmpty) ...[
              const SizedBox(height: 16),
              _MetricGrid(metrics: r.metrics, isDesktop: isDesktop),
            ],
            if (r.skills.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SkillBreakdown(skills: r.skills),
            ],
            if (r.experience.isNotEmpty || r.keywords.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ChartsRow(experience: r.experience, keywords: r.keywords),
            ],
            if (r.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              _RecommendationsFeed(recommendations: r.recommendations),
            ],
            const SizedBox(height: 24),
          ],
        );
    }
  }
}

// =============================================================================
// State widgets
// =============================================================================

class _NoCvState extends StatelessWidget {
  const _NoCvState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.upload_file_outlined,
                color: AppColors.textMuted, size: 56),
            const SizedBox(height: 20),
            Text(
              'Upload your CV to get analysis.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload your CV to get your ATS score, statistics, skill '
              'analysis, and personalized review.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Unable to analyze your CV right now. Please try again.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            _RetryButton(onTap: onRetry),
          ],
        ),
      ),
    );
  }
}

class _IncompleteState extends StatelessWidget {
  const _IncompleteState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sentiment_dissatisfied_rounded,
                color: AppColors.warning, size: 48),
            const SizedBox(height: 16),
            Text(
              'We couldn\'t extract enough information from this CV.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try uploading a different file format or a more detailed CV.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetryButton extends StatefulWidget {
  const _RetryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 250.ms,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: _hover ? 0.25 : 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh_rounded,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Retry',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreUnavailable extends StatelessWidget {
  const _ScoreUnavailable();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.help_outline_rounded,
            color: AppColors.textMuted, size: 48),
        const SizedBox(height: 12),
        Text(
          'ATS score unavailable',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        const Text(
          'The analysis did not include a score.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _RoleUnavailable extends StatelessWidget {
  const _RoleUnavailable();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.work_off_outlined, color: AppColors.textMuted, size: 16),
          SizedBox(width: 8),
          Text(
            'Role not determined',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Sub-widgets (kept in-file for cohesion — all part of the dashboard screen)
// =============================================================================

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.uploadPanel, required this.dashboard});

  final Widget uploadPanel;
  final Widget dashboard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: SingleChildScrollView(child: uploadPanel)),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: dashboard),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: AppTheme.accentGradient,
            boxShadow: [
              BoxShadow(color: AppColors.accentGlow, blurRadius: 14),
            ],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.accentGradient.createShader(bounds),
          child: const Text(
            'AI CV Analyzer',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    ).animate(onPlay: (c) => c.repeat()).shimmer(
        duration: 3000.ms, color: AppColors.accent.withValues(alpha: 0.3));
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.accent : AppColors.textSecondary,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          fontSize: 14,
        ),
      ).animate(target: active ? 1 : 0).fade(duration: 300.ms),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(8),
      child: const Icon(Icons.dark_mode_rounded,
          color: AppColors.accent, size: 18),
    );
  }
}

class _Avatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.accent.withValues(alpha: 0.2),
      child: const Icon(Icons.person, color: AppColors.accent, size: 20),
    );
  }
}

class _AnalyzeButton extends StatefulWidget {
  const _AnalyzeButton({required this.onTap, required this.loading});

  final VoidCallback onTap;
  final bool loading;

  @override
  State<_AnalyzeButton> createState() => _AnalyzeButtonState();
}

class _AnalyzeButtonState extends State<_AnalyzeButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.loading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: 250.ms,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: AppTheme.accentGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGlow,
                blurRadius: _hover ? 30 : 16,
                spreadRadius: _hover ? 2 : 0,
              ),
            ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Run ATS Analysis',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        )
            .animate(target: _hover ? 1 : 0)
            .scale(begin: const Offset(1, 1), end: const Offset(1.03, 1.03)),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(AppColors.accent),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1200.ms, color: AppColors.accent),
        const SizedBox(height: 16),
        const Text('Analyzing your CV…',
            style: TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics, required this.isDesktop});

  final List<MetricScore> metrics;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final crossCount = c.maxWidth >= 600 ? 2 : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.4,
        ),
        itemCount: metrics.length,
        itemBuilder: (context, i) {
          final m = metrics[i];
          return GlassContainer(
            padding: const EdgeInsets.all(14),
            child: _MetricCard(metric: m),
          )
              .animate()
              .fadeIn(delay: (80 * i).ms, duration: 400.ms)
              .slideY(begin: 0.08);
        },
      );
    });
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final MetricScore metric;

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(metric.value);
    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 46,
              height: 46,
              child: CircularProgressIndicator(
                value: metric.value / 100,
                strokeWidth: 5,
                color: color,
                backgroundColor: AppColors.bgElevated,
              ),
            ),
            Text(
              '${metric.value.round()}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(metric.label,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(height: 2),
              Text(metric.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkillBreakdown extends StatelessWidget {
  const _SkillBreakdown({required this.skills});

  final List<SkillTag> skills;

  @override
  Widget build(BuildContext context) {
    final matched = skills.where((s) => s.matched).toList();
    final missing = skills.where((s) => !s.matched).toList();
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Skill Match Breakdown',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          if (matched.isNotEmpty) ...[
            const Text('Matched Skills',
                style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: matched
                  .map((s) => _SkillChip(
                        label: s.name,
                        color: AppColors.success,
                        matched: true,
                      )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .scale(begin: const Offset(0.8, 0.8)))
                  .toList(),
            ),
          ],
          if (matched.isNotEmpty && missing.isNotEmpty)
            const SizedBox(height: 18),
          if (missing.isNotEmpty) ...[
            const Text('Missing Critical Skills',
                style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: missing
                  .map((s) => _SkillChip(
                        label: s.name,
                        color: AppColors.danger,
                        matched: false,
                        badge: s.recommendation,
                      )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .scale(begin: const Offset(0.8, 0.8)))
                  .toList(),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({
    required this.label,
    required this.color,
    required this.matched,
    this.badge,
  });

  final String label;
  final Color color;
  final bool matched;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(matched ? Icons.check_circle : Icons.error_outline,
              color: color, size: 15),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badge!, style: TextStyle(color: color, fontSize: 10)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartsRow extends StatelessWidget {
  const _ChartsRow({required this.experience, required this.keywords});

  final List<ExperienceSlice> experience;
  final List<KeywordDensity> keywords;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final side = c.maxWidth >= 700;
      final children = <Widget>[];
      if (experience.isNotEmpty) {
        children.add(Expanded(
          flex: 1,
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Experience Breakdown',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: _ExperienceBarChart(experience: experience),
                ),
              ],
            ),
          ),
        ));
      }
      if (keywords.isNotEmpty) {
        children.add(Expanded(
          flex: 1,
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Keyword Density',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: _KeywordPieChart(keywords: keywords),
                ),
              ],
            ),
          ),
        ));
      }
      if (side && children.length == 2) {
        return Flex(
          direction: Axis.horizontal,
          children: [
            children[0],
            const SizedBox(width: 12),
            children[1],
          ],
        );
      }
      return Flex(
        direction: Axis.vertical,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    });
  }
}

class _ExperienceBarChart extends StatelessWidget {
  const _ExperienceBarChart({required this.experience});

  final List<ExperienceSlice> experience;

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= experience.length) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(experience[i].label.split(' ').first,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: List.generate(experience.length, (i) {
          final e = experience[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: e.years,
                width: 18,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
                gradient: AppTheme.accentGradient,
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _KeywordPieChart extends StatelessWidget {
  const _KeywordPieChart({required this.keywords});

  final List<KeywordDensity> keywords;

  static const _colors = [
    AppColors.accent,
    AppColors.accentDim,
    AppColors.success,
    AppColors.warning,
    AppColors.danger,
    Color(0xFF818CF8),
  ];

  @override
  Widget build(BuildContext context) {
    final total = keywords.fold<int>(0, (a, k) => a + k.count).toDouble();
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: List.generate(keywords.length, (i) {
                final k = keywords[i];
                return PieChartSectionData(
                  value: k.count.toDouble(),
                  color: _colors[i % _colors.length],
                  radius: 50,
                  title: '${((k.count / total) * 100).round()}%',
                  titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                );
              }),
              sectionsSpace: 2,
              centerSpaceRadius: 28,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(keywords.length, (i) {
              final k = keywords[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _colors[i % _colors.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(k.keyword,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ),
                    Text('(${k.count})',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.work_outline_rounded,
              color: AppColors.accent, size: 16),
          const SizedBox(width: 8),
          Text(
            'Predicted: $category',
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationsFeed extends StatefulWidget {
  const _RecommendationsFeed({required this.recommendations});

  final List<Recommendation> recommendations;

  @override
  State<_RecommendationsFeed> createState() => _RecommendationsFeedState();
}

class _RecommendationsFeedState extends State<_RecommendationsFeed> {
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI Recommendations',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          ...widget.recommendations.map((rec) {
            final expanded = _expandedId == rec.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _expandedId = expanded ? null : rec.id),
                child: AnimatedContainer(
                  duration: 250.ms,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: rec.severity.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: rec.severity.color.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(rec.severity.icon,
                              color: rec.severity.color, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(rec.title,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ),
                          AnimatedRotation(
                            turns: expanded ? 0.5 : 0,
                            duration: 250.ms,
                            child: const Icon(Icons.expand_more,
                                color: AppColors.textSecondary, size: 20),
                          ),
                        ],
                      ),
                      AnimatedCrossFade(
                        duration: 250.ms,
                        crossFadeState: expanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(rec.detail,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: (60).ms, duration: 300.ms)
                .slideX(begin: 0.05);
          }),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}
