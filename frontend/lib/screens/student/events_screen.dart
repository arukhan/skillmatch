import 'package:flutter/material.dart';
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
  String _selectedFormat = 'All';

  int get _studentId => SessionController.instance.activeStudentProfileId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _futureEvents = LearningService.fetchEvents(_studentId);
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
                ? 'Registered for "${event.title}"!'
                : 'Registration cancelled.',
          ),
          backgroundColor:
              registered ? AppTheme.brandPurple : Colors.grey.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const filters = ['All', 'Offline', 'Online', 'Registered'];

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
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    children: filters.map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: _selectedFormat == f,
                          selectedColor: AppTheme.brandPurpleLight,
                          onSelected: (_) =>
                              setState(() => _selectedFormat = f),
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

                      final all = snapshot.data ?? [];
                      final events = all.where((e) {
                        if (_selectedFormat == 'Registered') {
                          return e.isRegistered;
                        }
                        if (_selectedFormat != 'All') {
                          return e.workFormat.toLowerCase() ==
                              _selectedFormat.toLowerCase();
                        }
                        return true;
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
                          return Card(
                            color: Colors.white,
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                            '${ev.registeredCount} going',
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
                                      children: ev.tags
                                          .map(
                                            (t) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 9,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.backgroundLight,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '#$t',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ev.isRegistered
                                        ? OutlinedButton.icon(
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
                                          )
                                        : ElevatedButton.icon(
                                            onPressed: () =>
                                                _toggleRegistration(ev),
                                            icon: const Icon(
                                              Icons.event_available,
                                              size: 18,
                                            ),
                                            label: const Text('Register Now'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.brandPurple,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
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