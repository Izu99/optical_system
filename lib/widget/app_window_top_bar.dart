import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

// Import your theme file - adjust the path as needed
// import 'path/to/your/theme_file.dart';

// Temporary ModernUIColors class - replace with import above
class ModernUIColors extends ThemeExtension<ModernUIColors> {
  final Color glassBg;
  final Color glassStroke;
  final Color hoverBg;
  final Color activeBg;
  final Color gradientStart;
  final Color gradientEnd;
  final Color accentGlow;

  const ModernUIColors({
    required this.glassBg,
    required this.glassStroke,
    required this.hoverBg,
    required this.activeBg,
    required this.gradientStart,
    required this.gradientEnd,
    required this.accentGlow,
  });

  @override
  ModernUIColors copyWith({
    Color? glassBg,
    Color? glassStroke,
    Color? hoverBg,
    Color? activeBg,
    Color? gradientStart,
    Color? gradientEnd,
    Color? accentGlow,
  }) {
    return ModernUIColors(
      glassBg: glassBg ?? this.glassBg,
      glassStroke: glassStroke ?? this.glassStroke,
      hoverBg: hoverBg ?? this.hoverBg,
      activeBg: activeBg ?? this.activeBg,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      accentGlow: accentGlow ?? this.accentGlow,
    );
  }

  @override
  ModernUIColors lerp(ThemeExtension<ModernUIColors>? other, double t) {
    if (other is! ModernUIColors) return this;
    return ModernUIColors(
      glassBg: Color.lerp(glassBg, other.glassBg, t) ?? glassBg,
      glassStroke: Color.lerp(glassStroke, other.glassStroke, t) ?? glassStroke,
      hoverBg: Color.lerp(hoverBg, other.hoverBg, t) ?? hoverBg,
      activeBg: Color.lerp(activeBg, other.activeBg, t) ?? activeBg,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t) ?? gradientStart,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t) ?? gradientEnd,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t) ?? accentGlow,
    );
  }
}

/// A beautiful, draggable custom top bar with window controls for desktop Flutter apps.
class AppWindowTopBar extends StatefulWidget {
  final double height;
  final Color? backgroundColor;
  final Border? border;
  final bool showGradientBorder;
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;

  const AppWindowTopBar({
    super.key,
    this.height = 48,
    this.backgroundColor,
    this.border,
    this.showGradientBorder = true,
    this.leading,
    this.title,
    this.actions,
  });

  @override
  State<AppWindowTopBar> createState() => _AppWindowTopBarState();
}

class _AppWindowTopBarState extends State<AppWindowTopBar> {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _checkMaximizedState();
  }

  void _checkMaximizedState() {
    // Check if window is maximized
    _isMaximized = appWindow.isMaximized;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final modernColors = Theme.of(context).extension<ModernUIColors>();
    
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? 
               modernColors?.glassBg ?? 
               colorScheme.surface.withOpacity(0.95),
        border: widget.border,
      ),
      child: Column(
        children: [
          // Main top bar content
          Expanded(
            child: Row(
              children: [
                // Leading widget (optional)
                if (widget.leading != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: widget.leading!,
                  ),
                  const SizedBox(width: 12),
                ],
                
                // Title (optional)
                if (widget.title != null) ...[
                  widget.title!,
                  const SizedBox(width: 16),
                ],
                
                // Drag area
                Expanded(
                  child: MoveWindow(
                    child: Container(
                      height: double.infinity,
                      color: Colors.transparent,
                    ),
                  ),
                ),
                
                // Custom actions (optional)
                if (widget.actions != null) ...[
                  ...widget.actions!,
                  const SizedBox(width: 8),
                ],
                
                // Window control buttons
                _buildWindowControls(context, colorScheme, modernColors),
              ],
            ),
          ),
          
          // Gradient border at bottom
          if (widget.showGradientBorder) _buildGradientBorder(modernColors),
        ],
      ),
    );
  }

  Widget _buildWindowControls(BuildContext context, ColorScheme colorScheme, ModernUIColors? modernColors) {
    return Row(
      children: [
        _WindowButton(
          icon: Icons.remove_rounded,
          onPressed: () => appWindow.minimize(),
          colorScheme: colorScheme,
          modernColors: modernColors,
          isDestructive: false,
        ),
        _WindowButton(
          icon: _isMaximized ? Icons.fullscreen_exit_rounded : Icons.crop_square_rounded,
          onPressed: () {
            appWindow.maximizeOrRestore();
            setState(() {
              _isMaximized = !_isMaximized;
            });
          },
          colorScheme: colorScheme,
          modernColors: modernColors,
          isDestructive: false,
        ),
        _WindowButton(
          icon: Icons.close_rounded,
          onPressed: () => appWindow.close(),
          colorScheme: colorScheme,
          modernColors: modernColors,
          isDestructive: true,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildGradientBorder(ModernUIColors? modernColors) {
    return Container(
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (modernColors?.gradientStart ?? const Color(0xFF667EEA)).withOpacity(0.3),
            (modernColors?.gradientEnd ?? const Color(0xFF764BA2)).withOpacity(0.3),
            const Color(0xFF06B6D4).withOpacity(0.3), // Cyan accent
            (modernColors?.gradientStart ?? const Color(0xFF667EEA)).withOpacity(0.3),
          ],
          stops: const [0.0, 0.33, 0.66, 1.0],
        ),
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final ColorScheme colorScheme;
  final ModernUIColors? modernColors;
  final bool isDestructive;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    required this.colorScheme,
    required this.modernColors,
    this.isDestructive = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
                decoration: BoxDecoration(
                  color: _getButtonColor(),
                  borderRadius: BorderRadius.circular(8),
                  border: _isHovered && !widget.isDestructive
                      ? Border.all(
                          color: (widget.modernColors?.glassStroke ?? Colors.grey.withOpacity(0.3)),
                          width: 0.5,
                        )
                      : null,
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: widget.isDestructive
                                ? Colors.red.withOpacity(0.2)
                                : (widget.modernColors?.accentGlow ?? widget.colorScheme.primary).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.icon,
                  size: 16,
                  color: _getIconColor(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getButtonColor() {
    if (!_isHovered) return Colors.transparent;
    
    if (widget.isDestructive) {
      return const Color(0xFFFF5449).withOpacity(0.9);
    }
    
    return widget.modernColors?.hoverBg ?? 
           widget.colorScheme.primary.withOpacity(0.08);
  }

  Color _getIconColor() {
    if (widget.isDestructive && _isHovered) {
      return Colors.white;
    }
    
    return widget.colorScheme.onSurface.withOpacity(_isHovered ? 0.9 : 0.7);
  }
}