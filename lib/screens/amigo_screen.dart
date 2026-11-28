import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../database/seed_data.dart';
import '../providers/auth_provider.dart';
import '../providers/pantry_provider.dart';
import '../utils/theme.dart';
import 'cooking_guide_screen.dart';
import 'recipe_detail_screen.dart';

final GlobalKey<NavigatorState> amigoNavigatorKey =
    GlobalKey<NavigatorState>();

/// Number of Amigo panels/screens currently open (button hides when > 0).
final ValueNotifier<int> _amigoOpenCount = ValueNotifier<int>(0);

final ValueNotifier<int> _modalRouteCount = ValueNotifier<int>(0);

class AmigoRouteObserver extends NavigatorObserver {
  void _change(Route<dynamic>? route, int delta) {
    if (route is! PopupRoute) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _modalRouteCount.value = math.max(0, _modalRouteCount.value + delta);
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _change(route, 1);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _change(route, -1);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _change(route, -1);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _change(oldRoute, -1);
    _change(newRoute, 1);
  }
}

final AmigoRouteObserver amigoRouteObserver = AmigoRouteObserver();

/// Clears Amigo's in-memory conversation (call on logout / user switch).
void resetAmigoChat() => _chat.reset();

/// Opens Amigo as a small bottom panel.
void showAmigoSheet([BuildContext? context]) {
  final ctx = context ?? amigoNavigatorKey.currentState?.overlay?.context;
  if (ctx == null || _amigoOpenCount.value > 0) return;

  showModalBottomSheet<void>(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      final mq = MediaQuery.of(sheetCtx);
      final available =
          mq.size.height - mq.viewInsets.bottom - mq.padding.top - 12;
      final height = math.min(mq.size.height * 0.62, available);
      return Padding(
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: SizedBox(
          height: height,
          child: const ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            child: _AmigoPanel(compact: true),
          ),
        ),
      );
    },
  );
}

class AmigoOverlay extends StatelessWidget {
  const AmigoOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        ListenableBuilder(
          listenable: Listenable.merge([_amigoOpenCount, _modalRouteCount]),
          builder: (context, _) {
            if (_amigoOpenCount.value > 0 || _modalRouteCount.value > 0) {
              return const SizedBox.shrink();
            }
            return const Positioned(
              right: 16,
              bottom: 96,
              child: _AmigoFab(),
            );
          },
        ),
      ],
    );
  }
}

class _AmigoFab extends StatelessWidget {
  const _AmigoFab();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3A847),
      elevation: 6,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => showAmigoSheet(),
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Icon(Icons.pets_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

String _normalizeIngredient(String raw) {
  var s = raw.trim().toLowerCase();
  if (s.endsWith('es') && s.length > 4) {
    s = s.substring(0, s.length - 2);
  } else if (s.endsWith('s') && !s.endsWith('ss') && s.length > 3) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

// SHARED CHAT STATE (same conversation in small panel + full screen)
class _AmigoChat extends ChangeNotifier {
  final List messages = [];
  bool typing = false;
  String timeLabel = '';
  int _session = 0;
  String? _activeUserId;

  /// Clears chat memory whenever the signed-in user changes or logs out.
  void syncUser(String? userId) {
    if (_activeUserId == userId) return;
    _activeUserId = userId;
    if (messages.isNotEmpty || typing) {
      _session++;
      messages.clear();
      typing = false;
      timeLabel = '';
    }
  }

  /// Recipe attached to the LATEST Amigo reply only. Returns null when the
  /// latest reply has no recipe (for example a meal plan).
  Map? get lastRecipe {
    for (final m in messages.reversed) {
      if (m['isUser'] == true) continue;
      return m['recipe'] as Map?;
    }
    return null;
  }

  void reset() {
    _session++;
    messages.clear();
    typing = false;
    timeLabel = '';
    notifyListeners();
  }

  Future<void> send(String text, PantryProvider provider) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || typing) return;

    final session = _session;

    if (messages.isEmpty) timeLabel = _formatTime(DateTime.now());
    messages.add({'isUser': true, 'text': trimmed});
    typing = true;
    notifyListeners();

    // Wait for the initial Supabase load to finish so slow networks never read
    // a stale or empty pantry.
    await provider.whenLoaded;
    if (session != _session) return;

    // Only include unexpired pantry items normalized for exact matching.
    final validNormalizedPantry = provider.items
        .where((e) => e.daysUntilExpiry == null || e.daysUntilExpiry! >= 0)
        .map((e) => _normalizeIngredient(e.name))
        .toSet();
    final equip = provider.selectedEquipment;

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (session != _session) return;

    messages.add(_buildAmigoReply(trimmed, validNormalizedPantry, equip));
    typing = false;
    notifyListeners();
  }
}

final _AmigoChat _chat = _AmigoChat();

String _formatTime(DateTime d) {
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final suffix = d.hour >= 12 ? 'PM' : 'AM';
  return 'Today · $hour12:$minute $suffix';
}

Map<String, dynamic> _buildAmigoReply(
  String query,
  Set<String> validNormalizedPantry,
  Set<String> selectedEquip,
) {
  final q = query.toLowerCase();

  // Substitution query: only when the user expresses swap / missing intent.
  final wantsSwap = q.contains('swap') ||
      q.contains('substitute') ||
      q.contains('replace') ||
      q.contains('missing') ||
      q.contains("don't have") ||
      q.contains('without');

  if (wantsSwap) {
    if (q.contains('cream')) {
      final hasMilk = validNormalizedPantry.contains('milk');
      final hasCheese = validNormalizedPantry.contains('cheese');
      if (hasMilk) {
        return {
          'isUser': false,
          'text':
              'No cream? You already have milk in your pantry—swap in 1/2 cup of milk + 1 tsp butter for the same creamy texture!',
        };
      }
      if (hasCheese) {
        return {
          'isUser': false,
          'text':
              'No cream? Melt a slice of the cheese from your pantry into warm broth for the same creamy texture!',
        };
      }
      return {
        'isUser': false,
        'text':
            'No cream? Swap in 1/2 cup of milk + 1 tsp butter (or a slice of cheese melted into warm broth) for the same creamy texture!',
      };
    }
    return {
      'isUser': false,
      'text':
          'Totally fine! Skip it, or add a pinch of garlic powder or soy sauce from your shelf for extra flavor.',
    };
  }

  // Weekly meal plan query filtered by user's registered equipment
  if (q.contains('plan') || q.contains('week') || q.contains('3 ')) {
    final matching = SeedData.seededRecipes.where((r) {
      final reqEquip = List.from(r['equipment'] ?? []);
      return selectedEquip.isEmpty ||
          reqEquip.any((e) => selectedEquip.contains(e));
    }).take(3).toList();

    final picks = matching.isNotEmpty
        ? matching
        : SeedData.seededRecipes.take(3).toList();
    const days = ['Mon', 'Tue', 'Wed'];
    final lines = [
      for (var i = 0; i < picks.length; i++)
        '• ${days[i]}: ${picks[i]['title']} (${picks[i]['prep_minutes']} min)',
    ].join('\n');

    return {
      'isUser': false,
      'text':
          'Here is a ${picks.length}-night budget dorm plan matched to your pantry & equipment:\n$lines',
    };
  }

  // Match requested equipment from user's prompt or registered equipment
  final requestedEquip = selectedEquip.cast<String?>().firstWhere(
        (e) => e != null && q.contains(e.toLowerCase()),
        orElse: () => null,
      );

  Map pickedRecipe = SeedData.seededRecipes.first;
  if (requestedEquip != null) {
    pickedRecipe = SeedData.seededRecipes.firstWhere(
      (r) => List.from(r['equipment'] ?? []).contains(requestedEquip),
      orElse: () => SeedData.seededRecipes.first,
    );
  } else {
    for (final r in SeedData.seededRecipes) {
      final reqEquip = List.from(r['equipment'] ?? []);
      final equipOk = selectedEquip.isEmpty ||
          reqEquip.any((e) => selectedEquip.contains(e));
      final ings = List.from(r['ingredients'] ?? []);
      final usesPantry = ings.any(
        (i) => validNormalizedPantry.contains(_normalizeIngredient(i.toString())),
      );
      if (equipOk && usesPantry) {
        pickedRecipe = r;
        break;
      }
    }
  }

  final equipText = requestedEquip != null
      ? 'Using your $requestedEquip, this fits right into your setup.'
      : 'Based on your pantry items and equipment, this uses what you already have.';

  return {
    'isUser': false,
    'text': "Easy! $equipText Here's my top pick:",
    'recipe': pickedRecipe,
  };
}

// FULL SCREEN
class AmigoScreen extends StatelessWidget {
  const AmigoScreen({super.key, this.initialPrompt});

  /// Optional message sent automatically when the screen opens.
  final String? initialPrompt;

  @override
  Widget build(BuildContext context) {
    return _AmigoPanel(compact: false, initialPrompt: initialPrompt);
  }
}

// PANEL (used for both the small sheet and the full screen)
const Color _amber = Color(0xFFF3A847);
const Color _headerGreen = Color(0xFFDCE8CE);

class _AmigoPanel extends StatefulWidget {
  const _AmigoPanel({required this.compact, this.initialPrompt});

  final bool compact;
  final String? initialPrompt;

  @override
  State<_AmigoPanel> createState() => _AmigoPanelState();
}

class _AmigoPanelState extends State<_AmigoPanel> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  String? _toastText;
  int _toastId = 0;

  List _starterPromptsFor(Set<String> equip) {
    final primaryEquip =
        equip.isNotEmpty ? equip.first.toLowerCase() : 'rice cooker';
    return [
      {
        'icon': Icons.restaurant_menu_rounded,
        'text': 'What can I cook tonight with what I have?',
      },
      {
        'icon': Icons.access_time_rounded,
        'text': 'Give me a 10-minute meal with just a $primaryEquip',
      },
      {
        'icon': Icons.autorenew_rounded,
        'text': "I'm missing cream. What can I swap?",
      },
      {
        'icon': Icons.calendar_today_rounded,
        'text': 'Plan 3 cheap dinners for this week',
      },
    ];
  }

  bool get _compact => widget.compact;

  @override
  void initState() {
    super.initState();
    _chat.addListener(_scrollToEnd);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amigoOpenCount.value = _amigoOpenCount.value + 1;
      final prompt = widget.initialPrompt;
      if (prompt != null && prompt.trim().isNotEmpty && mounted) {
        _submit(prompt);
      }
      _scrollToEnd();
    });
  }

  @override
  void dispose() {
    _chat.removeListener(_scrollToEnd);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amigoOpenCount.value = math.max(0, _amigoOpenCount.value - 1);
    });
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Helpers
  void _toast(String message) {
    final id = ++_toastId;
    setState(() => _toastText = message);
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && id == _toastId) setState(() => _toastText = null);
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _submit(String text) {
    if (text.trim().isEmpty || _chat.typing) return;
    _inputCtrl.clear();
    _chat.send(text, context.read<PantryProvider>());
  }

  void _expand() {
    final nav = amigoNavigatorKey.currentState;
    Navigator.of(context).pop(); // close the small panel
    nav?.push(MaterialPageRoute(builder: (_) => const AmigoScreen()));
  }

  void _close() => Navigator.of(context).pop();

  void _openRecipe(Map recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipe: recipe, matchPercent: 94),
      ),
    );
  }

  void _cookRecipe(Map recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CookingGuideScreen(recipe: recipe)),
    );
  }

  /// Adds the ingredients that are missing for the latest recipe to the
  /// shopping list stored in PantryProvider.
  void _addMissingToList() {
    final recipe = _chat.lastRecipe;
    if (recipe == null) {
      _toast('Ask for a recipe first');
      return;
    }
    final pantry = context.read<PantryProvider>();
    final missing =
        pantry.missingIngredients(List.from(recipe['ingredients'] ?? []));
    if (missing.isEmpty) {
      _toast('You already have everything!');
      return;
    }
    pantry.addToShoppingList(missing);
    _toast(
      'Added ${missing.length} item${missing.length == 1 ? '' : 's'} to your list',
    );
  }

  // Build
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<PantryProvider>();

    // Reset chat memory if the user switched accounts or logged out
    _chat.syncUser(auth.isGuest ? null : auth.email);

    final fullName = auth.displayName.trim();
    final firstName =
        fullName.isEmpty ? 'Chef' : fullName.split(RegExp(r'\s+')).first;

    final items = provider.items;
    final equip = provider.selectedEquipment;
    final starterPrompts = _starterPromptsFor(equip);

    // Distinguish already-expired items from urgent (0-3 day) items.
    final expired = provider.expiredItems;
    final urgent = provider.urgentItem;
    final String? alertName = urgent?.name.toLowerCase() ??
        (expired.isNotEmpty ? expired.first.name.toLowerCase() : null);
    final int alertDays = urgent != null
        ? (urgent.daysUntilExpiry ?? 0)
        : (expired.isNotEmpty ? (expired.first.daysUntilExpiry ?? -1) : 0);
    final bool isAlreadyExpired = urgent == null && expired.isNotEmpty;

    final equipSummary =
        equip.isEmpty ? 'Rice cooker · Kettle' : equip.join(' · ');

    return ListenableBuilder(
      listenable: _chat,
      builder: (context, _) {
        final isChatMode = _chat.messages.isNotEmpty;

        Widget body;
        if (_compact) {
          body = Column(
            children: [
              _buildCompactHeader(isChatMode, items.length),
              Expanded(
                child: isChatMode
                    ? _buildChatBody(
                        alertName,
                        alertDays,
                        equip,
                        showQuick: true,
                      )
                    : _buildCompactStart(
                        firstName: firstName,
                        itemCount: items.length,
                        urgentName: alertName,
                        urgentDays: alertDays,
                        isExpired: isAlreadyExpired,
                        equipSummary: equipSummary,
                        starterPrompts: starterPrompts,
                      ),
              ),
              _buildInputBar(isChatMode),
            ],
          );
        } else {
          body = Column(
            children: [
              Expanded(
                child: isChatMode
                    ? _buildFullChat(items.length, alertName, alertDays, equip)
                    : _buildFullStart(
                        firstName: firstName,
                        itemCount: items.length,
                        urgentName: alertName,
                        urgentDays: alertDays,
                        isExpired: isAlreadyExpired,
                        equipSummary: equipSummary,
                        starterPrompts: starterPrompts,
                      ),
              ),
              _buildInputBar(isChatMode),
            ],
          );
        }

        return Scaffold(
          backgroundColor: AppColors.cream,
          resizeToAvoidBottomInset: !_compact,
          body: Stack(
            children: [
              body,
              if (_toastText != null)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 84,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textDark,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _toastText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // COMPACT (small panel)
  Widget _buildCompactHeader(bool isChatMode, int itemCount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _avatar(34, 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amigo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      isChatMode
                          ? '● Using your pantry · $itemCount items'
                          : '● Your dorm cooking buddy',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ),
              if (isChatMode)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textDark,
                    size: 22,
                  ),
                  onSelected: (_) => _chat.reset(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'new', child: Text('New chat')),
                  ],
                ),
              IconButton(
                tooltip: 'Open full screen',
                onPressed: _expand,
                icon: const Icon(
                  Icons.open_in_full_rounded,
                  color: AppColors.textDark,
                  size: 20,
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: _close,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textDark,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStart({
    required String firstName,
    required int itemCount,
    required String? urgentName,
    required int urgentDays,
    required bool isExpired,
    required String equipSummary,
    required List starterPrompts,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 60,
                height: 60,
                child: CustomPaint(painter: _ChefCatPainter()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _greetingText(
                      firstName,
                      urgentName,
                      urgentDays,
                      isExpired: isExpired,
                      fontSize: 13,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _statusChip('✓ $itemCount items synced'),
                        _statusChip(equipSummary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'TRY ASKING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...starterPrompts.map((p) => _promptTile(p, small: true)),
      ],
    );
  }

  // FULL SCREEN
  Widget _buildFullStart({
    required String firstName,
    required int itemCount,
    required String? urgentName,
    required int urgentDays,
    required bool isExpired,
    required String equipSummary,
    required List starterPrompts,
  }) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              height: 215,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _headerGreen,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.elliptical(240, 64),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _circleButton(
                        Icons.arrow_back_ios_new_rounded,
                        () => Navigator.pop(context),
                        iconSize: 17,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amigo',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              '● Your dorm cooking buddy',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _circleButton(
                        Icons.history_rounded,
                        () => _toast('Chat history coming soon'),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              bottom: -44,
              child: SizedBox(
                width: 112,
                height: 112,
                child: CustomPaint(painter: _ChefCatPainter()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 60),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _greetingText(
                  firstName,
                  urgentName,
                  urgentDays,
                  isExpired: isExpired,
                  fontSize: 14.5,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusChip('✓ $itemCount items synced'),
                    _statusChip(equipSummary),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 22),
          child: Text(
            'TRY ASKING',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...starterPrompts.map(
          (p) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _promptTile(p, small: false),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFullChat(
    int itemCount,
    String? urgentName,
    int urgentDays,
    Set<String> equip,
  ) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 8, 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.paleGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 17,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _avatar(38, 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amigo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '● Using your pantry · $itemCount items',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textDark,
                    ),
                    onSelected: (_) => _chat.reset(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'new', child: Text('New chat')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildChatBody(urgentName, urgentDays, equip, showQuick: true),
        ),
      ],
    );
  }

  // CHAT BODY (messages + quick replies) — shared
  Widget _buildChatBody(
    String? urgentName,
    int urgentDays,
    Set<String> equip, {
    required bool showQuick,
  }) {
    final messages = _chat.messages;
    final typing = _chat.typing;
    final showQuickReplies = showQuick &&
        !typing &&
        messages.isNotEmpty &&
        messages.last['isUser'] != true;

    // "Start cooking" and "Add to list" only make sense when the latest
    // Amigo reply contains a recipe.
    final hasRecipe = _chat.lastRecipe != null;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: EdgeInsets.fromLTRB(
              _compact ? 16 : 20,
              14,
              _compact ? 16 : 20,
              12,
            ),
            itemCount: messages.length + 1 + (typing ? 1 : 0),
            itemBuilder: (context, idx) {
              if (idx == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Center(
                    child: Text(
                      _chat.timeLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }

              if (idx == messages.length + 1) return _buildTypingRow();

              final msg = messages[idx - 1];
              final isUser = msg['isUser'] == true;
              final text = msg['text'] as String;
              final recipe = msg['recipe'] as Map?;

              if (isUser) return _buildUserBubble(text);
              return _buildAmigoBubble(text, recipe, urgentName, urgentDays);
            },
          ),
        ),
        if (showQuickReplies)
          Padding(
            padding: EdgeInsets.fromLTRB(_compact ? 16 : 20, 4, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (hasRecipe) ...[
                    _quickPill('Start cooking', () {
                      final r = _chat.lastRecipe;
                      if (r != null) _cookRecipe(r);
                    }),
                    const SizedBox(width: 8),
                  ],
                  _quickPill('More ideas', () {
                    final primaryEquip = equip.isNotEmpty
                        ? equip.first.toLowerCase()
                        : 'rice cooker';
                    _submit('Plan 3 cheap dinners using my $primaryEquip');
                  }),
                  if (hasRecipe) ...[
                    const SizedBox(width: 8),
                    _quickPill('Add to list', _addMissingToList),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.green,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _avatar(30, 16),
          const SizedBox(width: 10),
          const Text(
            'Amigo is thinking…',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildAmigoBubble(
    String text,
    Map? recipe,
    String? urgentName,
    int urgentDays,
  ) {
    // Only show the "uses <item>" chip when the recipe contains an unexpired urgent item.
    final name = urgentName;
    final r = recipe;
    final usesUrgent = r != null &&
        name != null &&
        urgentDays >= 0 &&
        List.from(r['ingredients'] ?? []).any(
          (i) => _normalizeIngredient(i.toString()) == _normalizeIngredient(name),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _avatar(30, 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12, right: 24),
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (recipe != null)
          Container(
            margin: const EdgeInsets.fromLTRB(40, 0, 12, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAECD2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.ramen_dining_rounded,
                          size: 32,
                          color: Color(0xFFD98A2B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe['title'] as String,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${recipe['prep_minutes']} min · ${(recipe['ingredients'] as List).length} ingredients',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            if (usesUrgent) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  urgentDays == 0
                                      ? 'Uses $name · expires today'
                                      : 'Uses $name · ${urgentDays}d left',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFC53030),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _openRecipe(recipe),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              'View recipe',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Material(
                        color: AppColors.green,
                        child: InkWell(
                          onTap: () => _cookRecipe(recipe),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: Text(
                                'Cook now',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  // INPUT BAR (shared)
  Widget _buildInputBar(bool isChatMode) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(_compact ? 14 : 20, 8, _compact ? 14 : 20, 12),
        child: Row(
          children: [
            InkWell(
              onTap: () => _toast('Photo scan coming soon'),
              customBorder: const CircleBorder(),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.green,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.35),
                  ),
                ),
                child: TextField(
                  controller: _inputCtrl,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _submit,
                  decoration: const InputDecoration(
                    hintText: 'Ask Amigo anything...',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                if (!isChatMode && _inputCtrl.text.trim().isEmpty) {
                  _toast('Voice input coming soon');
                } else {
                  _submit(_inputCtrl.text);
                }
              },
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isChatMode ? Icons.send_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Small widgets — Handle expired items separately from expiring items.
  Widget _greetingText(
    String firstName,
    String? urgentName,
    int urgentDays, {
    required bool isExpired,
    required double fontSize,
  }) {
    final name = urgentName;
    final when = urgentDays == 0
        ? 'today'
        : 'in $urgentDays ${urgentDays == 1 ? 'day' : 'days'}';

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          color: AppColors.textDark,
          height: 1.4,
        ),
        children: [
          TextSpan(
            text: 'Hi $firstName! ',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (name == null)
            const TextSpan(
              text: 'I can see your pantry. Nothing is expiring soon, '
                  'so what would you like to cook?',
            )
          else if (isExpired || urgentDays < 0) ...[
            const TextSpan(text: 'I can see your pantry. Your '),
            TextSpan(
              text: '$name already expired',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const TextSpan(
              text: " — check if it's still safe before using it, "
                  'or let’s pick something else to cook.',
            ),
          ] else ...[
            const TextSpan(text: 'I can see your pantry. Your '),
            TextSpan(
              text: '$name expire $when',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const TextSpan(
              text: ", so let's use them first. What would you like to do?",
            ),
          ],
        ],
      ),
    );
  }

  Widget _promptTile(Map<String, dynamic> prompt, {required bool small}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(small ? 0 : 16, 0, small ? 0 : 16, 10),
      child: InkWell(
        onTap: () => _submit(prompt['text'] as String),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: EdgeInsets.all(small ? 11 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: small ? 34 : 38,
                height: small ? 34 : 38,
                decoration: BoxDecoration(
                  color: AppColors.paleGreen.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  prompt['icon'] as IconData,
                  color: AppColors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  prompt['text'] as String,
                  style: TextStyle(
                    fontSize: small ? 13 : 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton(
    IconData icon,
    VoidCallback onTap, {
    double iconSize = 20,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: iconSize, color: AppColors.textDark),
      ),
    );
  }

  Widget _avatar(double size, double iconSize) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: _amber, shape: BoxShape.circle),
      child: Icon(Icons.pets_rounded, color: Colors.white, size: iconSize),
    );
  }

  Widget _statusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.paleGreen.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.green,
        ),
      ),
    );
  }

  Widget _quickPill(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.green, width: 1.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.green,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// CHEF CAT MASCOT
class _ChefCatPainter extends CustomPainter {
  const _ChefCatPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final orange = Paint()..color = const Color(0xFFF2A154);
    final orangeDark = Paint()..color = const Color(0xFFE48B3A);
    final earInner = Paint()..color = const Color(0xFFF7C79B);
    final white = Paint()..color = Colors.white;
    final hatShade = Paint()
      ..color = const Color(0xFFE3E3E3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final blush = Paint()..color = const Color(0x66F28B82);
    final nose = Paint()..color = const Color(0xFFE76F7A);
    final eyeLine = Paint()
      ..color = const Color(0xFF5A3A22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final mouthLine = Paint()
      ..color = const Color(0xFF5A3A22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Ears
    final leftEar = Path()
      ..moveTo(w * 0.12, h * 0.60)
      ..lineTo(w * 0.14, h * 0.28)
      ..lineTo(w * 0.40, h * 0.46)
      ..close();
    final rightEar = Path()
      ..moveTo(w * 0.88, h * 0.60)
      ..lineTo(w * 0.86, h * 0.28)
      ..lineTo(w * 0.60, h * 0.46)
      ..close();
    canvas.drawPath(leftEar, orangeDark);
    canvas.drawPath(rightEar, orangeDark);

    final leftInner = Path()
      ..moveTo(w * 0.18, h * 0.54)
      ..lineTo(w * 0.19, h * 0.36)
      ..lineTo(w * 0.34, h * 0.46)
      ..close();
    final rightInner = Path()
      ..moveTo(w * 0.82, h * 0.54)
      ..lineTo(w * 0.81, h * 0.36)
      ..lineTo(w * 0.66, h * 0.46)
      ..close();
    canvas.drawPath(leftInner, earInner);
    canvas.drawPath(rightInner, earInner);

    // Face
    canvas.drawOval(
      Rect.fromLTWH(w * 0.08, h * 0.40, w * 0.84, h * 0.56),
      orange,
    );

    // Happy eyes
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.33, h * 0.68),
        width: w * 0.15,
        height: h * 0.13,
      ),
      math.pi,
      math.pi,
      false,
      eyeLine,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.67, h * 0.68),
        width: w * 0.15,
        height: h * 0.13,
      ),
      math.pi,
      math.pi,
      false,
      eyeLine,
    );

    // Blush
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.22, h * 0.78),
        width: w * 0.13,
        height: h * 0.08,
      ),
      blush,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.78, h * 0.78),
        width: w * 0.13,
        height: h * 0.08,
      ),
      blush,
    );

    // Nose + mouth
    final nosePath = Path()
      ..moveTo(w * 0.46, h * 0.76)
      ..lineTo(w * 0.54, h * 0.76)
      ..lineTo(w * 0.50, h * 0.80)
      ..close();
    canvas.drawPath(nosePath, nose);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.46, h * 0.82),
        width: w * 0.08,
        height: h * 0.06,
      ),
      0,
      math.pi,
      false,
      mouthLine,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.54, h * 0.82),
        width: w * 0.08,
        height: h * 0.06,
      ),
      0,
      math.pi,
      false,
      mouthLine,
    );

    // Chef hat
    canvas.drawCircle(Offset(w * 0.38, h * 0.20), w * 0.13, white);
    canvas.drawCircle(Offset(w * 0.50, h * 0.14), w * 0.16, white);
    canvas.drawCircle(Offset(w * 0.62, h * 0.20), w * 0.13, white);
    final band = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.30, h * 0.22, w * 0.40, h * 0.18),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(band, white);
    canvas.drawRRect(band, hatShade);
    canvas.drawLine(
      Offset(w * 0.30, h * 0.34),
      Offset(w * 0.70, h * 0.34),
      hatShade,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}