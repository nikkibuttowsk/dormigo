import 'package:material_ui/material_ui.dart';

import '../utils/theme.dart';
import 'login_screen.dart';

/// Figma screen 02: three swipeable pages with Skip and Next.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.line1,
    required this.line2,
    required this.body,
  });

  final IconData icon;
  final String line1;
  final String line2;
  final String body;
}

const _pages = [
  _OnboardingPage(
    icon: Icons.rice_bowl,
    line1: 'Small Choices.',
    line2: 'Big Impact.',
    body: 'Snap your groceries, track what expires, and turn leftovers '
        'into delicious dorm meals.',
  ),
  _OnboardingPage(
    icon: Icons.event_available,
    line1: 'Know What',
    line2: 'Expires Soon.',
    body: 'Keep quantities and expiry dates in one place and see which '
        'food to use first.',
  ),
  _OnboardingPage(
    icon: Icons.soup_kitchen,
    line1: 'Cook With',
    line2: 'What You Have.',
    body: 'Get recipes that fit your pantry and the appliances in your '
        'dorm: rice cooker, kettle, microwave, or hot plate.',
  ),
];

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _current = 0;

  bool get _isLast => _current == _pages.length - 1;

  void _finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (context, i) => _PageContent(page: _pages[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _current ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _current
                          ? AppColors.green
                          : AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
              child: ElevatedButton(
                onPressed: _next,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isLast ? 'Get Started' : 'Next'),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 230,
            height: 230,
            decoration: const BoxDecoration(
              color: AppColors.paleGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 110, color: AppColors.green),
          ),
          const SizedBox(height: 40),
          Text(
            page.line1,
            style: const TextStyle(fontSize: 22, color: AppColors.textDark),
          ),
          Text(
            page.line2,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}