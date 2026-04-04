import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lottie/lottie.dart';
import '../providers/stats_provider.dart';
import '../services/storage_service.dart';
import '../theme/lofi_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<StatsProvider>(); // Rebuild when stats change

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Lottie.asset('assets/animations/calendar.json', height: 120),
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            availableCalendarFormats: const { CalendarFormat.month: 'Month' },
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) {
              final progress = StorageService.getProgressForDate(day);
              if (progress != null && progress.completedSessions > 0) {
                return ['completed']; // Marker
              }
              return [];
            },
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: LofiTheme.primary,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: LofiTheme.primary.withOpacity(0.3), blurRadius: 8)],
              ),
              selectedDecoration: BoxDecoration(
                color: LofiTheme.secondary,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: LofiTheme.secondary.withOpacity(0.3), blurRadius: 10)],
              ),
              todayDecoration: BoxDecoration(
                color: LofiTheme.surfaceHighest,
                border: Border.all(color: LofiTheme.primary.withOpacity(0.5), width: 1.5),
                shape: BoxShape.circle,
              ),
              defaultTextStyle: const TextStyle(color: LofiTheme.onSurface),
              weekendTextStyle: const TextStyle(color: LofiTheme.secondary),
              outsideDaysVisible: false,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18) ?? const TextStyle(),
              leftChevronIcon: const Icon(Icons.chevron_left, color: LofiTheme.secondary),
              rightChevronIcon: const Icon(Icons.chevron_right, color: LofiTheme.secondary),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: const TextStyle(color: LofiTheme.outline, fontWeight: FontWeight.bold),
              weekendStyle: const TextStyle(color: LofiTheme.secondaryContainer, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _buildDayDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDetails() {
    if (_selectedDay == null) return const SizedBox.shrink();

    final progress = StorageService.getProgressForDate(_selectedDay!);

    if (progress == null || progress.completedSessions == 0) {
      return Center(
        child: Text(
          'No sessions completed on this day.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatColumn(
                  label: 'Focus Time',
                  value: '${progress.totalFocusMinutes}m',
                ),
                _StatColumn(
                  label: 'Pomodoros',
                  value: '${progress.completedSessions}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 32,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
