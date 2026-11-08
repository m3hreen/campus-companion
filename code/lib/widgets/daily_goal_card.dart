// Home and Study receive the same saved time and goal from MainScreen.
import 'package:flutter/material.dart';

class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({super.key, required this.studiedSeconds, required this.goalMinutes});
  final int studiedSeconds;
  final int goalMinutes;

  @override
  Widget build(BuildContext context) {
    final double progress = (studiedSeconds / (goalMinutes * 60)).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF397D78), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.flag_outlined, color: Colors.white), SizedBox(width: 10),
          Text('Daily Study Goal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17))]),
        const SizedBox(height: 18),
        Text('${studiedSeconds ~/ 60} / $goalMinutes minutes',
          style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: progress, minHeight: 9, color: Colors.white,
          backgroundColor: const Color(0xFF8FB9B5), borderRadius: BorderRadius.circular(10)),
        const SizedBox(height: 10),
        Text(progress >= 1 ? 'Daily goal reached!' : 'Every saved study session counts toward your goal.',
          style: const TextStyle(color: Colors.white, fontSize: 13)),
      ]),
    );
  }
}
