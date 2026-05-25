import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import '../services/database_service.dart';

/// Generates a random math question based on difficulty level.
/// Returns a map with 'question' string and 'answer' int.
Map<String, dynamic> generateQuestion(int difficulty) {
  final rand = Random();

  switch (difficulty) {
    case 0: // SD — basic arithmetic
      final ops = ['+', '-', '×'];
      final op = ops[rand.nextInt(ops.length)];
      final a = rand.nextInt(20) + 1;
      final b = rand.nextInt(20) + 1;
      int answer;
      if (op == '+') {
        answer = a + b;
      } else if (op == '-') {
        answer = (a - b).abs();
      } else {
        answer = a * b;
      }
      return {'question': '${op == '-' ? max(a, b) : a} $op ${op == '-' ? min(a, b) : b}', 'answer': answer};

    case 2: // SMA — exponents & roots
      final type = rand.nextInt(3);
      if (type == 0) {
        final a = rand.nextInt(10) + 2;
        return {'question': '$a²', 'answer': a * a};
      } else if (type == 1) {
        final squares = [4, 9, 16, 25, 36, 49, 64, 81, 100, 121, 144];
        final sq = squares[rand.nextInt(squares.length)];
        return {'question': '√$sq', 'answer': sqrt(sq.toDouble()).round()};
      } else {
        final a = rand.nextInt(12) + 2;
        final b = rand.nextInt(12) + 2;
        final c = rand.nextInt(20) + 1;
        return {'question': '$a × $b + $c', 'answer': a * b + c};
      }

    default: // SMP — multiplication + addition/subtraction combos
      final a = rand.nextInt(15) + 2;
      final b = rand.nextInt(15) + 2;
      final c = rand.nextInt(30) + 1;
      final addOrSub = rand.nextBool() ? '+' : '-';
      final answer = addOrSub == '+' ? a * b + c : a * b - c;
      return {'question': '$a × $b $addOrSub $c', 'answer': answer};
  }
}

class MathLockScreen extends StatefulWidget {
  final String appName;
  final IconData appIcon;
  final Color appColor;
  final String packageName;    // untuk logging ke database
  final int difficultyLevel;   // 0=SD, 1=SMP, 2=SMA
  final VoidCallback onUnlocked;
  final VoidCallback? onDismiss;

  const MathLockScreen({
    super.key,
    required this.appName,
    required this.appIcon,
    required this.appColor,
    this.packageName = '',
    this.difficultyLevel = 1,
    required this.onUnlocked,
    this.onDismiss,
  });

  @override
  State<MathLockScreen> createState() => _MathLockScreenState();
}

class _MathLockScreenState extends State<MathLockScreen> with SingleTickerProviderStateMixin {
  String _input    = '';
  late Map<String, dynamic> _question;
  bool _isError    = false;
  bool _isSuccess  = false;
  int  _attempts   = 0;
  late int _startTimeMs;
  late AnimationController _shakeController;
  late Animation<double>   _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _question     = generateQuestion(widget.difficultyLevel);
    _startTimeMs  = DateTime.now().millisecondsSinceEpoch;

    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnimation  = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKey(String digit) {
    if (_isSuccess) return;
    setState(() {
      _isError = false;
      if (_input.length < 6) _input += digit;
    });
  }

  void _onBackspace() {
    if (_isSuccess) return;
    setState(() {
      _isError = false;
      if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1);
    });
  }

  void _onSubmit() {
    if (_input.isEmpty || _isSuccess) return;
    _attempts++;
    final userAnswer = int.tryParse(_input);
    if (userAnswer == _question['answer']) {
      setState(() => _isSuccess = true);
      // Simpan event sukses ke database
      DatabaseService().insertEvent(UnlockEvent(
        packageName: widget.packageName,
        appName:     widget.appName,
        timestamp:   DateTime.now().millisecondsSinceEpoch,
        success:     true,
        attempts:    _attempts,
        durationMs:  DateTime.now().millisecondsSinceEpoch - _startTimeMs,
        formula:     _question['question'] as String,
        answer:      _question['answer']   as int,
      ));
      Future.delayed(const Duration(milliseconds: 600), widget.onUnlocked);
    } else {
      setState(() {
        _isError = true;
        _input   = '';
      });
      _shakeController.forward(from: 0);
    }
  }

  void _refreshQuestion() {
    setState(() {
      _question = generateQuestion(widget.difficultyLevel);
      _input = '';
      _isError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF060C17),
      body: Stack(
        children: [
          // Background glow blobs
          Positioned(
            top: -size.height * 0.1,
            left: -size.width * 0.1,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            right: -size.width * 0.1,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Brand header
                Opacity(
                  opacity: 0.8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security, color: theme.colorScheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'COBALT FORTRESS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontSize: 11,
                          letterSpacing: 3.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 32),

                          // App icon with lock badge
                          _buildAppIcon(theme),

                          const SizedBox(height: 24),

                          // Title
                          Text(
                            'Security Verification',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontSize: 11,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Selesaikan soal untuk membuka ${widget.appName}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 28),

                          // Question + Input card
                          _buildQuestionCard(theme),

                          const SizedBox(height: 24),

                          // Number pad
                          _buildNumberPad(theme),

                          const SizedBox(height: 24),

                          // Emergency / dismiss button
                          GestureDetector(
                            onTap: widget.onDismiss,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.colorScheme.outlineVariant),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.emergency_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 8),
                                  Text(
                                    'PANGGILAN DARURAT',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 10,
                                      letterSpacing: 1.0,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppIcon(ThemeData theme) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: widget.appColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.appColor.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(color: widget.appColor.withValues(alpha: 0.2), blurRadius: 30),
            ],
          ),
          child: Icon(widget.appIcon, color: widget.appColor, size: 36),
        ),
        Positioned(
          bottom: -6,
          right: -6,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF060C17), width: 2),
              boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.4), blurRadius: 8)],
            ),
            child: const Icon(Icons.lock_rounded, size: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF0f172a).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              // Refresh + question
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _question['question'],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _refreshQuestion,
                    child: Opacity(
                      opacity: 0.5,
                      child: Icon(Icons.refresh_rounded, color: theme.colorScheme.primary, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Input display
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  final offset = _isError
                      ? sin(_shakeAnimation.value * pi * 6) * 12
                      : 0.0;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 72,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0a0e16),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isError
                          ? theme.colorScheme.error
                          : _isSuccess
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.primary.withValues(alpha: 0.5),
                      width: _isError || _isSuccess ? 2 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isError
                                ? theme.colorScheme.error
                                : _isSuccess
                                    ? theme.colorScheme.tertiary
                                    : theme.colorScheme.primary)
                            .withValues(alpha: 0.15),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _isSuccess
                      ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.check_circle_rounded, color: theme.colorScheme.tertiary, size: 28),
                          const SizedBox(width: 10),
                          Text('BENAR!', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.tertiary, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        ])
                      : _isError
                          ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.cancel_rounded, color: theme.colorScheme.error, size: 24),
                              const SizedBox(width: 8),
                              Text('JAWABAN SALAH', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            ])
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _input.isEmpty ? '—' : _input,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: _input.isEmpty ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary,
                                    letterSpacing: 6,
                                  ),
                                ),
                                if (_input.isNotEmpty)
                                  ...List.generate(1, (_) => _blinkCursor(theme)),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blinkCursor(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (_, v, _) => AnimatedOpacity(
        opacity: v > 0.5 ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.only(left: 4),
          width: 2,
          height: 28,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildNumberPad(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: [
          for (int n in [1, 2, 3, 4, 5, 6, 7, 8, 9])
            _buildDigitKey(theme, '$n'),
          _buildActionKey(
            theme,
            child: Icon(Icons.backspace_outlined, color: theme.colorScheme.onSurfaceVariant, size: 22),
            onTap: _onBackspace,
            color: Colors.transparent,
          ),
          _buildDigitKey(theme, '0'),
          _buildActionKey(
            theme,
            child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 26),
            onTap: _onSubmit,
            color: theme.colorScheme.primary,
            glow: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDigitKey(ThemeData theme, String digit) {
    return GestureDetector(
      onTap: () => _onKey(digit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        decoration: BoxDecoration(
          color: const Color(0xFF1e293b).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFFe2e8f0),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey(
    ThemeData theme, {
    required Widget child,
    required VoidCallback onTap,
    required Color color,
    bool glow = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: color == Colors.transparent ? null : Border.all(color: color),
          boxShadow: glow
              ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.4), blurRadius: 20)]
              : null,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
