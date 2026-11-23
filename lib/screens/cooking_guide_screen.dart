import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../utils/theme.dart';

class CookingGuideScreen extends StatefulWidget {
  final Map recipe;

  const CookingGuideScreen({super.key, required this.recipe});

  @override
  State<CookingGuideScreen> createState() => _CookingGuideScreenState();
}

class _CookingGuideScreenState extends State<CookingGuideScreen> {
  int _currentStep = 0;
  int _secondsRemaining = 480; // 08:00 default step timer
  Timer? _timer;
  bool _isRunning = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          t.cancel();
          setState(() => _isRunning = false);
        }
      });
    }
  }

  String _formatTime(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _goToStep(int index, int totalSteps) {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _currentStep = index;
      _secondsRemaining = index == 0 ? 480 : 180;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.recipe['title'] as String;
    final steps = List.from(widget.recipe['steps'] ?? []);
    final equipment = List.from(widget.recipe['equipment'] ?? ['Dorm Cooker']);
    final totalSteps = steps.isEmpty ? 1 : steps.length;
    final stepText = steps.isEmpty
        ? 'Prepare and cook ingredients until done.'
        : steps[_currentStep].toString();
    final isLastStep = _currentStep == totalSteps - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF233827),
      body: Column(
        children: [
          // Top Dark Forest Illustration & Progress
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Step ${_currentStep + 1} of $totalSteps · $title',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Segmented Progress Bar
                            Row(
                              children: List.generate(totalSteps, (idx) {
                                final active = idx <= _currentStep;
                                return Expanded(
                                  child: Container(
                                    height: 4,
                                    margin: EdgeInsets.only(
                                      right: idx == totalSteps - 1 ? 0 : 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? Colors.white
                                          : Colors.white24,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Pot Illustration
                  Container(
                    width: 130,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8C9296),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.soup_kitchen_rounded,
                      size: 64,
                      color: Color(0xFFF3D59B),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Cream Step Sheet
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step ${_currentStep + 1}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    stepText,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textDark,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Interactive Timer Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.green,
                              width: 3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatTime(_secondsRemaining),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const Text(
                                'Timer · tap to start',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _toggleTimer,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(105, 42),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          icon: Icon(
                            _isRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 18,
                          ),
                          label: Text(_isRunning ? 'Pause' : 'Start'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Equipment + Portion Chips
                  Row(
                    children: [
                      Expanded(
                        child: _metaBox(
                          Icons.countertops_rounded,
                          equipment.first.toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metaBox(
                          Icons.local_fire_department_rounded,
                          'Dorm-safe heat',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Amigo Tip
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.paleGreen.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE5A43B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.tips_and_updates_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Amigo: Keep a lid handy to trap heat and save dorm electricity!',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom Back / Next Step Controls
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          onPressed: _currentStep == 0
                              ? () => Navigator.pop(context)
                              : () => _goToStep(_currentStep - 1, totalSteps),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 52),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.black12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: const Text(
                            '← Back',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: () {
                            if (!isLastStep) {
                              _goToStep(_currentStep + 1, totalSteps);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '🎉 Finished $title! Ingredients logged as Used.',
                                  ),
                                ),
                              );
                              Navigator.popUntil(
                                  context, (route) => route.isFirst);
                            }
                          },
                          child: Text(
                            isLastStep ? 'Finish Cooking ✓' : 'Next step →',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaBox(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.paleGreen.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}