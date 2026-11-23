import 'package:material_ui/material_ui.dart';

import '../utils/theme.dart';
import 'onboarding_screen.dart';

/// Figma screen 01: logo, mascot and a "Get Started" button.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Decorative circles at the bottom (a Stack lets widgets overlap).
          Positioned(
            left: -100,
            bottom: -120,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                color: AppColors.lightGreen,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -80,
            bottom: -200,
            child: Container(
              width: 420,
              height: 420,
              decoration: const BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  // Logo text with a leaf icon at the top-right corner.
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Text(
                        'Dormigo',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green,
                        ),
                      ),
                      Positioned(
                        top: -22,
                        right: -26,
                        child: Transform.rotate(
                          angle: 0.5,
                          child: const Icon(
                            Icons.eco,
                            size: 36,
                            color: AppColors.lightGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cook Smart. Waste Less.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  // Placeholder mascot. Later: Image.asset('assets/mascot.png')
                  Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                      color: AppColors.paleGreen,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('🦊', style: TextStyle(fontSize: 110)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.green,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OnboardingScreen(),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Get Started'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'A greener dorm, a happier you.',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}