// Seven vertical bars, a shared minutes scale, and exact-value tooltips.
// No chart dependency: layout widgets keep the chart easy to explain and theme.
import 'dart:math' as math;
import 'package:flutter/material.dart';

class WeeklyStudyChart extends StatelessWidget {
  const WeeklyStudyChart({super.key, required this.dates, required this.seconds});
  final List<DateTime> dates;
  final List<int> seconds;

  String _minutes(int value) => value % 60 == 0 ? '${value ~/ 60}' : (value / 60).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final int peak = seconds.fold<int>(0, (int largest, int value) => value > largest ? value : largest);
    final double ceiling = math.max(1, (peak / 60).ceil()).toDouble();
    final ColorScheme colors = Theme.of(context).colorScheme;
    const List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Minutes studied'),
      const SizedBox(height: 12),
      SizedBox(height: 200, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 36, height: 146, child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('${ceiling.toInt()}'), Text((ceiling / 2).toStringAsFixed(1)), const Text('0')])),
        Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (int index = 0; index < dates.length; index++)
            Expanded(child: Semantics(
              label: '${days[dates[index].weekday - 1]} ${dates[index].day}/${dates[index].month}: ${seconds[index] ~/ 60} minutes ${seconds[index] % 60} seconds',
              child: Tooltip(message: '${seconds[index] ~/ 60} min ${seconds[index] % 60} sec', child: Column(children: [
                Text(_minutes(seconds[index]), style: Theme.of(context).textTheme.labelSmall, maxLines: 1),
                const SizedBox(height: 4),
                Container(height: 126, margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(widthFactor: 1,
                    heightFactor: ((seconds[index] / 60) / ceiling).clamp(0.0, 1.0).toDouble(),
                    child: DecoratedBox(decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(6))))),
                const SizedBox(height: 8),
                Text(days[dates[index].weekday - 1], style: Theme.of(context).textTheme.labelSmall),
                Text('${dates[index].day}/${dates[index].month}', style: Theme.of(context).textTheme.labelSmall),
              ])),
            )),
        ])),
      ])),
    ]);
  }
}
