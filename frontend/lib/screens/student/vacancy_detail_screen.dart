import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/vacancy.dart';
import '../../services/vacancy_service.dart';
import '../../state/session_controller.dart';
import '../../widgets/match_badge.dart';

class VacancyDetailScreen extends StatefulWidget {
  final Vacancy? vacancy;
  const VacancyDetailScreen({super.key, this.vacancy});

  @override
  State<VacancyDetailScreen> createState() => _VacancyDetailScreenState();
}

class _VacancyDetailScreenState extends State<VacancyDetailScreen> {
  Vacancy? _vacancy;
  bool _isLoading = true;
  bool _isApplying = false;
  bool _initialized = false;

  int get _studentId => SessionController.instance.activeStudentProfileId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (widget.vacancy != null) {
      _vacancy = widget.vacancy;
      _isLoading = false;
      _refreshVacancy(_vacancy!.id);
    } else if (args is Vacancy) {
      _vacancy = args;
      _isLoading = false;
      _refreshVacancy(args.id);
    } else if (args is int) {
      _refreshVacancy(args);
    } else if (SessionController.instance.activeVacancyId != null) {
      _refreshVacancy(SessionController.instance.activeVacancyId!);
    } else {
      _isLoading = false;
    }
  }

  Future<void> _refreshVacancy(int vacancyId) async {
    try {
      final list = await VacancyService.fetchVacancies(
        studentId: _studentId,
        includeInactive: true,
      );
      final found = list.where((v) => v.id == vacancyId).toList();
      if (!mounted) return;
      setState(() {
        if (found.isNotEmpty) {
          _vacancy = found.first;
        }
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openApplyDialog(Vacancy v) async {
    final coverCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Apply to ${v.title}'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      v.companyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  MatchBadge(score: v.matchScore.toDouble()),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: coverCtrl,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Cover Note (optional)',
                  hintText:
                      'Tell the recruiter about your relevant projects, GitHub, or Telegram...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send Application'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isApplying = true);
    try {
      await VacancyService.applyToVacancy(
        vacancyId: v.id,
        studentProfileId: _studentId,
        matchScore: v.matchScore,
        coverLetter: coverCtrl.text.trim(),
      );
      await _refreshVacancy(v.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application sent to company!'),
          backgroundColor: AppTheme.brandPurple,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _vacancy;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          SessionController.instance.closeVacancyDetail();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vacancy Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              SessionController.instance.closeVacancyDetail();
              Navigator.pop(context);
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : v == null
                ? const Center(child: Text('Vacancy not found.'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 740),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                v.title,
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                v.companyName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: AppTheme.brandPurple,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        MatchBadge(
                                          score: v.matchScore.toDouble(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        Chip(
                                          avatar: const Icon(
                                            Icons.location_on_outlined,
                                            size: 16,
                                          ),
                                          label: Text(v.location),
                                        ),
                                        Chip(
                                          avatar: const Icon(
                                            Icons.laptop_mac_outlined,
                                            size: 16,
                                          ),
                                          label: Text(v.workFormat),
                                        ),
                                        Chip(
                                          avatar: const Icon(
                                            Icons.schedule_outlined,
                                            size: 16,
                                          ),
                                          label: Text(v.employmentType),
                                        ),
                                        Chip(
                                          avatar: const Icon(
                                            Icons.work_history_outlined,
                                            size: 16,
                                          ),
                                          label: Text(
                                            '${v.experienceRequired} yrs exp',
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (v.salaryRange.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        'Compensation: ${v.salaryRange}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.brandPurple,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (v.hasApplied) ...[
                              const SizedBox(height: 12),
                              Card(
                                color: v.appliedStatus == 'Approved'
                                    ? Colors.green.shade50
                                    : v.appliedStatus == 'Rejected'
                                        ? Colors.red.shade50
                                        : v.appliedStatus == 'Interview'
                                            ? Colors.orange.shade50
                                            : AppTheme.brandPurpleLight,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Application Status: ${v.appliedStatus}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (v.companyFeedback.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Response from ${v.companyName}: ${v.companyFeedback}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Card(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Skill Match Breakdown',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (v.matchedSkills.isNotEmpty) ...[
                                      const Text(
                                        'Matched Skills',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: v.matchedSkills
                                            .map(
                                              (s) => Chip(
                                                avatar: const Icon(
                                                  Icons.check_circle,
                                                  size: 16,
                                                  color: Colors.green,
                                                ),
                                                label: Text(s),
                                                backgroundColor:
                                                    Colors.green.shade50,
                                              ),
                                            )
                                            .toList(),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (v.missingSkills.isNotEmpty) ...[
                                      const Text(
                                        'Skills to Improve / Missing',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: v.missingSkills
                                            .map(
                                              (s) => Chip(
                                                avatar: const Icon(
                                                  Icons.cancel_outlined,
                                                  size: 16,
                                                  color: Colors.red,
                                                ),
                                                label: Text(s),
                                                backgroundColor:
                                                    Colors.red.shade50,
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Job Description',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      v.description.isNotEmpty
                                          ? v.description
                                          : 'No detailed description provided.',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: (!v.isActive ||
                                        v.hasApplied ||
                                        _isApplying)
                                    ? null
                                    : () => _openApplyDialog(v),
                                icon: Icon(
                                  v.hasApplied
                                      ? Icons.check_circle_outline
                                      : Icons.send_rounded,
                                ),
                                label: Text(
                                  !v.isActive
                                      ? 'Vacancy Paused'
                                      : v.hasApplied
                                          ? 'Status: ${v.appliedStatus}'
                                          : 'Apply Now',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.brandPurple,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}