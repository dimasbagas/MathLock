import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import '../state/app_state.dart';
import '../widgets/mock_ad_banner.dart';
import '../widgets/ambient_glow.dart';
import '../services/ad_service.dart';

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

    case 3: // PT / Pakar — Hard multi-step algebra with parenthesis (e.g. a(x + b) + c = d(x + e))
      int x = 0;
      int a = 0;
      int b = 0;
      int d = 0;
      int e = 0;
      int c = 0;

      // Loop to ensure we get a valid, non-trivial equation
      for (int i = 0; i < 100; i++) {
        // x (answer) should be between -12 and 12, but not 0, 1, or -1 to keep it challenging
        final xVal = rand.nextInt(25) - 12; // -12 to 12
        x = (xVal == 0 || xVal == 1 || xVal == -1) ? (rand.nextBool() ? 5 : -5) : xVal;
        
        a = rand.nextInt(5) + 2; // 2 to 6
        b = rand.nextInt(17) - 8; // -8 to 8 (can be negative)
        if (b == 0) b = 3;
        
        d = rand.nextInt(5) + 2; // 2 to 6
        while (d == a) {
          d = rand.nextInt(5) + 2;
        }
        
        e = rand.nextInt(17) - 8; // -8 to 8 (can be negative)
        if (e == 0) e = -3;
        
        c = d * (x + e) - a * (x + b);
        
        // Ensure c is non-zero and we don't have trivial coefficients
        if (c != 0) {
          break;
        }
      }

      // Format left side: a(x + b) + c
      String leftSide = '$a(x';
      if (b > 0) {
        leftSide += ' + $b)';
      } else {
        leftSide += ' - ${b.abs()})';
      }

      if (c > 0) {
        leftSide += ' + $c';
      } else {
        leftSide += ' - ${c.abs()}';
      }

      // Format right side: d(x + e)
      String rightSide = '$d(x';
      if (e > 0) {
        rightSide += ' + $e)';
      } else {
        rightSide += ' - ${e.abs()})';
      }

      return {'question': 'Cari x: $leftSide = $rightSide', 'answer': x};

    case 1:
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
  final AppState appState;
  final String appName;
  final IconData appIcon;
  final Color appColor;
  final String packageName;    // untuk logging ke database
  final int difficultyLevel;   // 0=SD, 1=SMP, 2=SMA
  final VoidCallback onUnlocked;
  final VoidCallback? onDismiss;

  const MathLockScreen({
    super.key,
    required this.appState,
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

  int _secondsLeft = 10;
  int _currentQuestionIndex = 1;
  int _attemptsLeft = 3;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _question     = generateQuestion(widget.difficultyLevel);
    _startTimeMs  = DateTime.now().millisecondsSinceEpoch;

    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnimation  = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _startTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsLeft = 10;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _handleTimeout();
        }
      });
    });
  }

  void _handleTimeout() {
    _attemptsLeft--;
    _isError = true;
    _input = '';
    _shakeController.forward(from: 0);

    if (_attemptsLeft <= 0) {
      _nextQuestionOrExit();
    } else {
      _startTimer();
    }
  }

  void _nextQuestionOrExit() {
    if (_currentQuestionIndex < 3) {
      setState(() {
        _currentQuestionIndex++;
        _attemptsLeft = 3;
        _question = generateQuestion(widget.difficultyLevel);
        _input = '';
        _isError = false;
      });
      _startTimer();
    } else {
      _countdownTimer?.cancel();
      _handleLockout();
    }
  }

  void _handleLockout() {
    // Simpan event gagal ke database
    DatabaseService().insertEvent(UnlockEvent(
      packageName: widget.packageName,
      appName:     widget.appName,
      timestamp:   DateTime.now().millisecondsSinceEpoch,
      success:     false,
      attempts:    _attempts,
      durationMs:  DateTime.now().millisecondsSinceEpoch - _startTimeMs,
      formula:     _question['question'] as String,
      answer:      _question['answer']   as int,
    ));

    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else {
      // Panggil native channel untuk keluar ke home launcher
      const MethodChannel('com.example.mathlockv2/lock').invokeMethod<void>('exitToHome');
    }
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

  void _onMinus() {
    if (_isSuccess) return;
    setState(() {
      _isError = false;
      if (_input.startsWith('-')) {
        _input = _input.substring(1);
      } else {
        if (_input.length < 6) {
          _input = '-$_input';
        }
      }
    });
  }

  void _onSubmit() {
    if (_input.isEmpty || _isSuccess) return;
    _attempts++;
    final userAnswer = int.tryParse(_input);
    if (userAnswer == _question['answer']) {
      _countdownTimer?.cancel();
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
      Future.delayed(const Duration(milliseconds: 600), () {
        AdService.instance.showAdWithCallback(() {
          widget.onUnlocked();
        });
      });
    } else {
      setState(() {
        _isError = true;
        _input   = '';
        _attemptsLeft--;
      });
      _shakeController.forward(from: 0);

      if (_attemptsLeft <= 0) {
        _nextQuestionOrExit();
      } else {
        _startTimer();
      }
    }
  }

  void _refreshQuestion() {
    setState(() {
      _question = generateQuestion(widget.difficultyLevel);
      _input = '';
      _isError = false;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          AmbientGlow.primary(
            top: -size.height * 0.1,
            left: -size.width * 0.1,
            size: size.width * 0.6,
            sigmaX: 80,
            sigmaY: 80,
            alpha: 0.25,
            context: context,
          ),
          AmbientGlow.primary(
            bottom: -size.height * 0.1,
            right: -size.width * 0.1,
            size: size.width * 0.6,
            sigmaX: 80,
            sigmaY: 80,
            alpha: 0.15,
            context: context,
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

                          const SizedBox(height: 16),

                          // Ad Banner for Free Users
                          MockAdBanner(appState: widget.appState, compact: true),

                          const SizedBox(height: 16),

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
              border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
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
            color: theme.cardColor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              // Time & attempts info row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(3, (i) {
                      final active = i < _attemptsLeft;
                      return Icon(
                        active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: active ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        size: 16,
                      );
                    }).map((w) => Padding(padding: const EdgeInsets.only(right: 4), child: w)).toList(),
                  ),
                  Text(
                    'SOAL $_currentQuestionIndex/3',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _secondsLeft <= 3 
                          ? theme.colorScheme.error.withValues(alpha: 0.15) 
                          : theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: _secondsLeft <= 3 ? theme.colorScheme.error : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_secondsLeft}s',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: _secondsLeft <= 3 ? theme.colorScheme.error : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Refresh + question
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _question['question'],
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
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
                    color: theme.scaffoldBackgroundColor,
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
                                  style: GoogleFonts.jetBrainsMono(
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
      child: Column(
        children: [
          GridView.count(
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
                child: Text(
                  '-',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onTap: _onMinus,
                color: theme.cardColor,
              ),
              _buildDigitKey(theme, '0'),
              _buildActionKey(
                theme,
                child: Icon(Icons.backspace_outlined, color: theme.colorScheme.onSurfaceVariant, size: 22),
                onTap: _onBackspace,
                color: Colors.transparent,
                border: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSubmitButton(theme),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return GestureDetector(
      onTap: _onSubmit,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
            )
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'SUBMIT JAWABAN',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitKey(ThemeData theme, String digit) {
    return GestureDetector(
      onTap: () => _onKey(digit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
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
    bool border = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: border ? Border.all(color: theme.colorScheme.outlineVariant) : null,
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
