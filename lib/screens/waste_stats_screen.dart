import 'package:material_ui/material_ui.dart';
import '../utils/theme.dart';

class WasteStatsScreen extends StatelessWidget {
  const WasteStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List weeklyBars = const [
      {'label': 'W1', 'pct': 42, 'color': Color(0xFF81B968)},
      {'label': 'W2', 'pct': 55, 'color': Color(0xFF72B059)},
      {'label': 'W3', 'pct': 66, 'color': Color(0xFF479647)},
      {'label': 'W4', 'pct': 72, 'color': AppColors.green},
    ];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Food Waste Monitor',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('How Waste Reduction Works'),
                        content: const Text(
                          'Dormigo tracks every pantry item you cook or finish before its expiry date versus items discarded.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Got it'),
                          ),
                        ],
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.textDark,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Circular 72% Ring
            Center(
              child: SizedBox(
                width: 175,
                height: 175,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 165,
                      height: 165,
                      child: CircularProgressIndicator(
                        value: 0.72,
                        strokeWidth: 14,
                        backgroundColor: AppColors.paleGreen,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.green,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.eco_rounded,
                          color: AppColors.green,
                          size: 20,
                        ),
                        Text(
                          '72%',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Food waste reduced',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // This Month Section
            const Text(
              'This Month',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    icon: Icons.check_rounded,
                    iconBg: AppColors.paleGreen,
                    iconColor: AppColors.green,
                    count: '44',
                    label: 'Used',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    icon: Icons.autorenew_rounded,
                    iconBg: const Color(0xFFDCEBFA),
                    iconColor: const Color(0xFF2B6CB0),
                    count: '3',
                    label: 'Saved',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    icon: Icons.delete_outline_rounded,
                    iconBg: const Color(0xFFFDE2E2),
                    iconColor: const Color(0xFFC53030),
                    count: '1',
                    label: 'Discarded',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Waste Reduced by Week Bar Chart Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Waste reduced by week',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: weeklyBars.map((bar) {
                      final pct = bar['pct'] as int;
                      final label = bar['label'] as String;
                      final color = bar['color'] as Color;
                      return Column(
                        children: [
                          Text(
                            '$pct%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 34,
                            height: pct * 1.15,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Encouraging Footer Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.paleGreen.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5A43B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Great job! You're up 6% on last week. Keep going!",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            count,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}