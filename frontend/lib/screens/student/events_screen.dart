import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_theme.dart';
import '../../services/learning_service.dart';
import '../../state/session_controller.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late Future<List<EventItem>> _futureEvents;
  final _searchCtrl = TextEditingController();
  String _selectedFilter = 'All';

  int get _studentId => SessionController.instance.activeStudentProfileId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _futureEvents = LearningService.fetchEvents(_studentId);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleRegistration(EventItem event) async {
    try {
      final registered = await LearningService.toggleEventRegistration(
        event.id,
        _studentId,
      );
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            registered
                ? 'Registered for "${event.title}"! Your Event Pass is ready.'
                : 'Registration cancelled.',
          ),
          backgroundColor:
              registered ? Colors.green.shade700 : Colors.grey.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showEventPass(EventItem ev) {
    final session = SessionController.instance.session;
    final attendeeName = session?.displayName ?? 'SkillMatch Student';
    final passCode =
        'SM-${ev.id.toString().padLeft(2, '0')}-${_studentId.toString().padLeft(4, '0')}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.confirmation_number_outlined,
                color: AppTheme.brandPurple),
            SizedBox(width: 8),
            Text('Event Entry Pass'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.brandPurpleLight.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.brandPurple.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ev.eventType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: AppTheme.brandPurple,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ev.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hosted by ${ev.organizer}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const Divider(height: 22),
                _passRow('Attendee', attendeeName),
                const SizedBox(height: 6),
                _passRow('Date & Time', ev.eventDate),
                const SizedBox(height: 6),
                _passRow('Location', ev.location),
                const SizedBox(height: 6),
                _passRow('Pass ID', passCode),
              ],
            ),
          ),
        ),
        actions: [
          if (ev.externalUrl.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: ev.externalUrl));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event page link copied!')),
                );
              },
              icon: const Icon(Icons.link_rounded, size: 18),
              label: const Text('Copy Link'),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _passRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const filters = ['All', 'Recommended', 'Offline', 'Online', 'Registered'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tech Events & Hackathons'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(_reload),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_reload);
          await _futureEvents;
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText:
                          'Search events by title, organizer, or stack (AI, SQL, Python)...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                SizedBox(
                  height: 46,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                    children: filters.map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: _selectedFilter == f,
                          selectedColor: AppTheme.brandPurpleLight,
                          onSelected: (_) =>
                              setState(() => _selectedFilter = f),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<EventItem>>(
                    future: _futureEvents,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Could not load events:\n${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final q = _searchCtrl.text.trim().toLowerCase();
                      final all = snapshot.data ?? [];
                      final events = all.where((e) {
                        if (_selectedFilter == 'Recommended') {
                          if (!e.isRecommended) return false;
                        } else if (_selectedFilter == 'Registered') {
                          if (!e.isRegistered) return false;
                        } else if (_selectedFilter != 'All') {
                          if (e.workFormat.toLowerCase() !=
                              _selectedFilter.toLowerCase()) {
                            return false;
                          }
                        }
                        if (q.isEmpty) return true;
                        return e.title.toLowerCase().contains(q) ||
                            e.organizer.toLowerCase().contains(q) ||
                            e.location.toLowerCase().contains(q) ||
                            e.tags.any((t) => t.toLowerCase().contains(q));
                      }).toList();

                      if (events.isEmpty) {
                        return const Center(
                          child: Text('No events match this filter.'),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: events.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final ev = events[index];
                          final matchedLower = ev.matchedTags
                              .map((t) => t.toLowerCase())
                              .toSet();

                          return Card(
                            color: Colors.white,
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (ev.isRecommended) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.brandPurpleLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.auto_awesome,
                                            size: 14,
                                            color: AppTheme.brandPurple,
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              'Matches your stack: ${ev.matchedTags.join(', ')}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.brandPurple,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          ev.eventType,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.brandPurple,
                                          ),
                                        ),
                                        backgroundColor:
                                            AppTheme.brandPurpleLight,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          ev.workFormat,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.people_outline,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${ev.registeredCount}/${ev.capacity} spots',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    ev.title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Hosted by ${ev.organizer}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.brandPurple,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 15,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        ev.eventDate,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 15,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          ev.location,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (ev.description.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      ev.description,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[800],
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                  if (ev.tags.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: ev.tags.map((t) {
                                        final isMatched = matchedLower
                                            .contains(t.toLowerCase());
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isMatched
                                                ? Colors.green.shade50
                                                : AppTheme.backgroundLight,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isMatched ? '✓ #$t' : '#$t',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isMatched
                                                  ? Colors.green.shade900
                                                  : Colors.black87,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (ev.isRegistered) ...[
                                        TextButton.icon(
                                          onPressed: () => _showEventPass(ev),
                                          icon: const Icon(
                                            Icons.confirmation_number_outlined,
                                            size: 18,
                                            color: AppTheme.brandPurple,
                                          ),
                                          label: const Text(
                                            'View Pass',
                                            style: TextStyle(
                                              color: AppTheme.brandPurple,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () =>
                                              _toggleRegistration(ev),
                                          icon: const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Registered (Cancel)',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ] else
                                        ElevatedButton.icon(
                                          onPressed: ev.isFull
                                              ? null
                                              : () => _toggleRegistration(ev),
                                          icon: const Icon(
                                            Icons.event_available,
                                            size: 18,
                                          ),
                                          label: Text(
                                            ev.isFull
                                                ? 'Event Full'
                                                : 'Register Now',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.brandPurple,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}