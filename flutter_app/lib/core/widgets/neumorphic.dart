import "package:flutter/material.dart";

/// Drive India PDF wali Neumorphism design system.
/// Halka grey-neela background, naram dual shadows, orange accent.
class NeuColors {
  static const bg = Color(0xFFE8EDF3);
  static const card = Color(0xFFE8EDF3);
  static const textDark = Color(0xFF1F2A44);
  static const textMuted = Color(0xFF8A94A6);
  static const accent = Color(0xFFF2994A);
  static const accentDark = Color(0xFFE8830C);
  static const success = Color(0xFF27AE60);
  static const error = Color(0xFFEB5757);
  static const shadowDark = Color(0xFFB8C2D1);
  static const shadowLight = Color(0xFFFFFFFF);

  static const accentGradient = LinearGradient(
    colors: [Color(0xFFF6B25C), Color(0xFFF2994A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class NeuShadows {
  /// Uthi hui (raised) cheezon ke liye
  static List<BoxShadow> raised({double blur = 14, double offset = 6}) => [
        BoxShadow(
          color: NeuColors.shadowDark.withValues(alpha: 0.55),
          blurRadius: blur,
          offset: Offset(offset, offset),
        ),
        const BoxShadow(
          color: NeuColors.shadowLight,
          blurRadius: 14,
          offset: Offset(-6, -6),
        ),
      ];

  /// Dabi hui (inset jaisi) cheezon ke liye — halka inner effect
  static List<BoxShadow> pressed() => [
        BoxShadow(
          color: NeuColors.shadowDark.withValues(alpha: 0.5),
          blurRadius: 10,
          offset: const Offset(4, 4),
        ),
        const BoxShadow(
          color: NeuColors.shadowLight,
          blurRadius: 10,
          offset: Offset(-4, -4),
        ),
      ];

  static List<BoxShadow> accentButton() => [
        BoxShadow(
          color: NeuColors.accent.withValues(alpha: 0.45),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Naram uthi hui card — PDF ke har card jaisi.
class NeuCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  const NeuCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: NeuColors.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: NeuShadows.raised(),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      child: card,
    );
  }
}

/// Andar dabi hui (inset) patti — text fields, search bar, chhote badges.
class NeuInset extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const NeuInset({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFDFE6EE),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: NeuColors.shadowDark.withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(3, 3),
          ),
          const BoxShadow(
            color: NeuColors.shadowLight,
            blurRadius: 8,
            offset: Offset(-3, -3),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Bada orange button — PDF ke "Verify", "Post Requirement" jaisa.
class NeuButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  const NeuButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: NeuColors.accentGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: NeuShadows.accentButton(),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 19),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Gol naram icon button — bell, back, search wagera ke liye.
class NeuIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color iconColor;
  const NeuIconBtn({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 46,
    this.iconColor = NeuColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: NeuColors.card,
          shape: BoxShape.circle,
          boxShadow: NeuShadows.raised(blur: 10, offset: 4),
        ),
        child: Icon(icon, color: iconColor, size: size * 0.46),
      ),
    );
  }
}

/// Naram text field — PDF ke input boxes jaisa.
class NeuTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  const NeuTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NeuInset(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 19, color: NeuColors.textMuted),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              onChanged: onChanged,
              style: const TextStyle(
                  color: NeuColors.textDark,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                    color: NeuColors.textMuted,
                    fontWeight: FontWeight.w500,
                    fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen ka upari hissa — back button + title, PDF jaisa.
class NeuHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  const NeuHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NeuIconBtn(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: NeuColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                      color: NeuColors.textMuted, fontSize: 12.5),
                ),
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}
