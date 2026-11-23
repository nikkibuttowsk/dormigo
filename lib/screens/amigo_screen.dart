import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../database/seed_data.dart';
import '../providers/pantry_provider.dart';
import '../utils/theme.dart';
import 'cooking_guide_screen.dart';
import 'recipe_detail_screen.dart';

class AmigoScreen extends StatefulWidget {
  const AmigoScreen({super.key});

  @override
  State<AmigoScreen> createState() => _AmigoScreenState();
}

class _AmigoScreenState extends State<AmigoScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List _messages = [];

  final List _starterPrompts = const [
    {
      'icon': Icons.restaurant_menu_rounded,
      'text': 'What can I cook tonight with what I have?',
    },
    {
      'icon': Icons.access_time_rounded,
      'text': 'Give me a 10-minute meal with just a kettle',
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

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final provider = context.read<PantryProvider>();
    final pantryNames =
        provider.items.map((e) => e.name.toLowerCase()).toList();
    final equip = provider.selectedEquipment;

    setState(() {
      _messages.add({'isUser': true, 'text': trimmed});
      _inputCtrl.clear();
    });

    // Build smart pantry-aware Amigo reply
    final reply = _buildAmigoReply(trimmed, pantryNames, equip);
    setState(() {
      _messages.add(reply);
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Map _buildAmigoReply(
    String query,
    List pantryNames,
    Set selectedEquip,
  ) {
    final q = query.toLowerCase();

    // Substitution query
    if (q.contains('swap') ||
        q.contains('missing') ||
        q.contains("don't have")) {
      if (q.contains('cream')) {
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

    // Weekly meal plan query
    if (q.contains('plan') || q.contains('week') || q.contains('3 ')) {
      return {
        'isUser': false,
        'text':
            'Here is a 3-night budget dorm plan using your pantry:\n• Mon: Creamy Egg Fried Rice (15 min)\n• Tue: Kettle Egg Drop Ramen (7 min)\n• Wed: Tomato & Egg Stir-Fry over Rice (10 min)',
      };
    }

    // Kettle / recipe recommendation
    Map pickedRecipe = SeedData.seededRecipes.first;
    if (q.contains('kettle')) {
      pickedRecipe = SeedData.seededRecipes.firstWhere(
        (r) => List.from(r['equipment'] ?? []).contains('Kettle'),
        orElse: () => SeedData.seededRecipes[3],
      );
    } else {
      // Pick best matching recipe for current pantry
      for (final r in SeedData.seededRecipes) {
        final reqEquip = List.from(r['equipment'] ?? []);
        final equipOk = selectedEquip.isEmpty ||
            reqEquip.any((e) => selectedEquip.contains(e));
        final ings = List.from(r['ingredients'] ?? []);
        final usesPantry = ings.any((i) =>
            pantryNames.any((p) => p.contains(i.toString().toLowerCase())));
        if (equipOk && usesPantry) {
          pickedRecipe = r;
          break;
        }
      }
    }

    final equipText = q.contains('kettle')
        ? 'With a kettle, your eggs and noodles work great.'
        : 'Based on your pantry items, this uses ingredients you already have.';

    return {
      'isUser': false,
      'text': "Easy! $equipText Here's my top pick:",
      'recipe': pickedRecipe,
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final items = provider.items;
    final equip = provider.selectedEquipment;

    // Find most urgent expiring item for the greeting card
    final now = DateTime.now();
    final urgentItems = items
        .where((item) =>
            item.expiryDate != null &&
            item.expiryDate!.difference(now).inDays <= 3)
        .toList();
    final urgentName =
        urgentItems.isNotEmpty ? urgentItems.first.name.toLowerCase() : 'eggs';
    final urgentDays = urgentItems.isNotEmpty
        ? urgentItems.first.expiryDate!.difference(now).inDays.clamp(0, 99)
        : 2;
    final equipSummary =
        equip.isEmpty ? 'Rice cooker · Kettle' : equip.join(' · ');

    final isChatMode = _messages.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          if (!isChatMode)
            // ================= 14 ASK AMIGO · START =================
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Curved Header + Cat Chef Mascot
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 205,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCE8CE),
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
                                InkWell(
                                  onTap: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 17,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                InkWell(
                                  onTap: () => _sendMessage(
                                    'What can I cook tonight with what I have?',
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.history_rounded,
                                      size: 20,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Cat Chef Avatar Badge
                      Positioned(
                        bottom: -36,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.soup_kitchen_rounded,
                                size: 22,
                                color: AppColors.textDark,
                              ),
                            ),
                            Container(
                              width: 78,
                              height: 66,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3A847),
                                borderRadius: BorderRadius.circular(32),
                                border:
                                    Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Icon(
                                Icons.pets_rounded,
                                size: 38,
                                color: Color(0xFF4A2C0A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Greeting & Pantry Sync Card
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
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14.5,
                                color: AppColors.textDark,
                                height: 1.4,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Hi Chloe! ',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const TextSpan(
                                  text: 'I can see your pantry. Your ',
                                ),
                                TextSpan(
                                  text:
                                      '$urgentName expire in $urgentDays ${urgentDays == 1 ? 'day' : 'days'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const TextSpan(
                                  text:
                                      ", so let's use them first. What would you like to do?",
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _statusChip('✓ ${items.length} items synced'),
                              _statusChip(equipSummary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // TRY ASKING Section
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

                  ..._starterPrompts.map(
                    (prompt) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: InkWell(
                        onTap: () => _sendMessage(prompt['text'] as String),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(14),
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
                                  color: AppColors.paleGreen
                                      .withValues(alpha: 0.75),
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
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // ================= 15 ASK AMIGO · CHAT =================
            Expanded(
              child: Column(
                children: [
                  // Top Chat Bar
                  SafeArea(
                    bottom: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black12),
                        ),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => setState(() => _messages.clear()),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
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
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3A847),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.pets_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
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
                                  '● Using your pantry · ${items.length} items',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _messages.clear()),
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Messages Feed
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                      itemCount: _messages.length + 1,
                      itemBuilder: (context, idx) {
                        if (idx == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 14),
                            child: Center(
                              child: Text(
                                'Today · Just now',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }

                        final msg = _messages[idx - 1];
                        final isUser = msg['isUser'] == true;
                        final text = msg['text'] as String;
                        final recipe = msg['recipe'] as Map?;

                        if (isUser) {
                          return Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 14, left: 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
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

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF3A847),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.pets_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                      bottom: 12,
                                      right: 24,
                                    ),
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

                            // Embedded Recipe Card if Amigo suggested a meal
                            if (recipe != null)
                              Container(
                                margin:
                                    const EdgeInsets.fromLTRB(40, 0, 12, 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
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
                                              borderRadius:
                                                  BorderRadius.circular(14),
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                                const SizedBox(height: 6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFFDE2E2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    'Uses $urgentName · ${urgentDays}d left',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFFC53030),
                                                    ),
                                                  ),
                                                ),
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
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    RecipeDetailScreen(
                                                  recipe: recipe,
                                                  matchPercent: 94,
                                                ),
                                              ),
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 12),
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
                                          child: InkWell(
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    CookingGuideScreen(
                                                  recipe: recipe,
                                                ),
                                              ),
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                              decoration: const BoxDecoration(
                                                color: AppColors.green,
                                                borderRadius: BorderRadius.only(
                                                  bottomRight:
                                                      Radius.circular(18),
                                                ),
                                              ),
                                              child: const Center(
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
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Quick Follow-up Chips in Chat Mode
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _quickPill('Start cooking', () {
                            _sendMessage(
                              'What can I cook tonight with what I have?',
                            );
                          }),
                          const SizedBox(width: 8),
                          _quickPill('More ideas', () {
                            _sendMessage('Plan 3 cheap dinners for this week');
                          }),
                          const SizedBox(width: 8),
                          _quickPill('Missing ingredient?', () {
                            _sendMessage("I'm missing cream. What can I swap?");
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Bottom Input Bar (Shared between Start & Chat modes)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Row(
                children: [
                  Container(
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: TextField(
                        controller: _inputCtrl,
                        onSubmitted: _sendMessage,
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
                    onTap: () => _sendMessage(_inputCtrl.text),
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
          ),
        ],
      ),
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