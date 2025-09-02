import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AnimationType {
  slideIn,
  fadeIn,
  scaleIn,
  bounceIn,
  rotateIn,
  flipIn,
  elastic,
  pulse,
}

enum AnimationSpeed {
  slow,
  normal,
  fast,
}

class AnimationConfig {
  final bool enabled;
  final AnimationSpeed speed;
  final bool reduceMotion;
  final Map<String, bool> specificAnimations;

  AnimationConfig({
    this.enabled = true,
    this.speed = AnimationSpeed.normal,
    this.reduceMotion = false,
    this.specificAnimations = const {},
  });

  Duration get duration {
    switch (speed) {
      case AnimationSpeed.slow:
        return const Duration(milliseconds: 800);
      case AnimationSpeed.normal:
        return const Duration(milliseconds: 400);
      case AnimationSpeed.fast:
        return const Duration(milliseconds: 200);
    }
  }

  Duration get shortDuration => Duration(milliseconds: (duration.inMilliseconds * 0.6).round());
  Duration get longDuration => Duration(milliseconds: (duration.inMilliseconds * 1.5).round());

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'speed': speed.name,
    'reduceMotion': reduceMotion,
    'specificAnimations': specificAnimations,
  };

  factory AnimationConfig.fromJson(Map<String, dynamic> json) {
    return AnimationConfig(
      enabled: json['enabled'] ?? true,
      speed: AnimationSpeed.values.firstWhere(
        (s) => s.name == json['speed'],
        orElse: () => AnimationSpeed.normal,
      ),
      reduceMotion: json['reduceMotion'] ?? false,
      specificAnimations: Map<String, bool>.from(json['specificAnimations'] ?? {}),
    );
  }

  AnimationConfig copyWith({
    bool? enabled,
    AnimationSpeed? speed,
    bool? reduceMotion,
    Map<String, bool>? specificAnimations,
  }) {
    return AnimationConfig(
      enabled: enabled ?? this.enabled,
      speed: speed ?? this.speed,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      specificAnimations: specificAnimations ?? this.specificAnimations,
    );
  }
}

class AnimationsService extends ChangeNotifier {
  AnimationConfig _config = AnimationConfig();
  static const String _configKey = 'animation_config';

  // Getters
  AnimationConfig get config => _config;
  bool get animationsEnabled => _config.enabled && !_config.reduceMotion;
  Duration get defaultDuration => _config.duration;
  AnimationSpeed get speed => _config.speed;

  /// Initialize animations service
  Future<void> initialize() async {
    await _loadConfig();
  }

  /// Load configuration from storage
  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);
      
      if (configJson != null) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          await compute(_parseJson, configJson),
        );
        _config = AnimationConfig.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error loading animation config: $e');
    }
  }

  /// Save configuration to storage
  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = await compute(_stringifyJson, _config.toJson());
      await prefs.setString(_configKey, configJson);
    } catch (e) {
      debugPrint('Error saving animation config: $e');
    }
  }

  /// Update animation configuration
  Future<void> updateConfig(AnimationConfig newConfig) async {
    _config = newConfig;
    await _saveConfig();
    notifyListeners();
  }

  /// Toggle animations on/off
  Future<void> toggleAnimations() async {
    await updateConfig(_config.copyWith(enabled: !_config.enabled));
  }

  /// Set animation speed
  Future<void> setAnimationSpeed(AnimationSpeed speed) async {
    await updateConfig(_config.copyWith(speed: speed));
  }

  /// Toggle reduce motion
  Future<void> toggleReduceMotion() async {
    await updateConfig(_config.copyWith(reduceMotion: !_config.reduceMotion));
  }

  /// Enable/disable specific animation
  Future<void> setSpecificAnimation(String animationKey, bool enabled) async {
    final newAnimations = Map<String, bool>.from(_config.specificAnimations);
    newAnimations[animationKey] = enabled;
    await updateConfig(_config.copyWith(specificAnimations: newAnimations));
  }

  /// Check if specific animation is enabled
  bool isAnimationEnabled(String animationKey) {
    if (!animationsEnabled) return false;
    return _config.specificAnimations[animationKey] ?? true;
  }

  /// Get animation curve based on type
  Curve getAnimationCurve(AnimationType type) {
    if (_config.reduceMotion) return Curves.linear;
    
    switch (type) {
      case AnimationType.slideIn:
        return Curves.easeOutCubic;
      case AnimationType.fadeIn:
        return Curves.easeInOut;
      case AnimationType.scaleIn:
        return Curves.elasticOut;
      case AnimationType.bounceIn:
        return Curves.bounceOut;
      case AnimationType.rotateIn:
        return Curves.easeOutBack;
      case AnimationType.flipIn:
        return Curves.easeOutExpo;
      case AnimationType.elastic:
        return Curves.elasticOut;
      case AnimationType.pulse:
        return Curves.easeInOutSine;
    }
  }

  /// Create slide transition
  Widget createSlideTransition({
    required Widget child,
    required Animation<double> animation,
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
    String? animationKey,
  }) {
    if (!isAnimationEnabled(animationKey ?? 'slide')) {
      return child;
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: getAnimationCurve(AnimationType.slideIn),
      )),
      child: child,
    );
  }

  /// Create fade transition
  Widget createFadeTransition({
    required Widget child,
    required Animation<double> animation,
    double begin = 0.0,
    double end = 1.0,
    String? animationKey,
  }) {
    if (!isAnimationEnabled(animationKey ?? 'fade')) {
      return child;
    }

    return FadeTransition(
      opacity: Tween<double>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: getAnimationCurve(AnimationType.fadeIn),
      )),
      child: child,
    );
  }

  /// Create scale transition
  Widget createScaleTransition({
    required Widget child,
    required Animation<double> animation,
    double begin = 0.0,
    double end = 1.0,
    String? animationKey,
  }) {
    if (!isAnimationEnabled(animationKey ?? 'scale')) {
      return child;
    }

    return ScaleTransition(
      scale: Tween<double>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: getAnimationCurve(AnimationType.scaleIn),
      )),
      child: child,
    );
  }

  /// Create rotation transition
  Widget createRotationTransition({
    required Widget child,
    required Animation<double> animation,
    double begin = 0.0,
    double end = 1.0,
    String? animationKey,
  }) {
    if (!isAnimationEnabled(animationKey ?? 'rotate')) {
      return child;
    }

    return RotationTransition(
      turns: Tween<double>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: getAnimationCurve(AnimationType.rotateIn),
      )),
      child: child,
    );
  }

  /// Create combined transition
  Widget createCombinedTransition({
    required Widget child,
    required Animation<double> animation,
    bool slide = false,
    bool fade = false,
    bool scale = false,
    bool rotate = false,
    Offset slideBegin = const Offset(0.0, 1.0),
    String? animationKey,
  }) {
    if (!isAnimationEnabled(animationKey ?? 'combined')) {
      return child;
    }

    Widget result = child;

    if (rotate) {
      result = createRotationTransition(
        child: result,
        animation: animation,
        animationKey: animationKey,
      );
    }

    if (scale) {
      result = createScaleTransition(
        child: result,
        animation: animation,
        animationKey: animationKey,
      );
    }

    if (slide) {
      result = createSlideTransition(
        child: result,
        animation: animation,
        begin: slideBegin,
        animationKey: animationKey,
      );
    }

    if (fade) {
      result = createFadeTransition(
        child: result,
        animation: animation,
        animationKey: animationKey,
      );
    }

    return result;
  }

  /// Create staggered animation
  Widget createStaggeredAnimation({
    required Widget child,
    required Animation<double> animation,
    required int index,
    required int totalItems,
    AnimationType type = AnimationType.fadeIn,
    String? animationKey,
  }) {
    if (!isAnimationEnabled(animationKey ?? 'stagger')) {
      return child;
    }

    final staggerDelay = 0.1 * index / totalItems;
    final staggerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Interval(
        staggerDelay,
        1.0,
        curve: getAnimationCurve(type),
      ),
    ));

    switch (type) {
      case AnimationType.fadeIn:
        return createFadeTransition(
          child: child,
          animation: staggerAnimation,
          animationKey: animationKey,
        );
      case AnimationType.slideIn:
        return createSlideTransition(
          child: child,
          animation: staggerAnimation,
          animationKey: animationKey,
        );
      case AnimationType.scaleIn:
        return createScaleTransition(
          child: child,
          animation: staggerAnimation,
          animationKey: animationKey,
        );
      default:
        return createFadeTransition(
          child: child,
          animation: staggerAnimation,
          animationKey: animationKey,
        );
    }
  }

  /// Create hero animation
  Widget createHeroTransition({
    required String tag,
    required Widget child,
    String? animationKey,
  }) {
    if (!isAnimationEnabled(animationKey ?? 'hero')) {
      return child;
    }

    return Hero(
      tag: tag,
      child: child,
    );
  }

  /// Create page transition
  PageRouteBuilder createPageTransition({
    required Widget page,
    AnimationType type = AnimationType.slideIn,
    String? animationKey,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: _config.duration,
      reverseTransitionDuration: _config.shortDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (!isAnimationEnabled(animationKey ?? 'page')) {
          return child;
        }

        switch (type) {
          case AnimationType.slideIn:
            return createSlideTransition(
              child: child,
              animation: animation,
              animationKey: animationKey,
            );
          case AnimationType.fadeIn:
            return createFadeTransition(
              child: child,
              animation: animation,
              animationKey: animationKey,
            );
          case AnimationType.scaleIn:
            return createScaleTransition(
              child: child,
              animation: animation,
              animationKey: animationKey,
            );
          default:
            return createSlideTransition(
              child: child,
              animation: animation,
              animationKey: animationKey,
            );
        }
      },
    );
  }

  /// Animate list item changes
  Widget createAnimatedListItem({
    required Widget child,
    required Animation<double> animation,
    required int index,
    AnimationType type = AnimationType.slideIn,
    String? animationKey,
  }) {
    if (!isAnimationEnabled(animationKey ?? 'list_item')) {
      return child;
    }

    switch (type) {
      case AnimationType.slideIn:
        return createSlideTransition(
          child: child,
          animation: animation,
          begin: const Offset(-1.0, 0.0),
          animationKey: animationKey,
        );
      case AnimationType.fadeIn:
        return createFadeTransition(
          child: child,
          animation: animation,
          animationKey: animationKey,
        );
      case AnimationType.scaleIn:
        return createScaleTransition(
          child: child,
          animation: animation,
          animationKey: animationKey,
        );
      default:
        return createSlideTransition(
          child: child,
          animation: animation,
          animationKey: animationKey,
        );
    }
  }

  /// Get animation settings for UI
  Map<String, dynamic> getAnimationSettings() {
    return {
      'enabled': _config.enabled,
      'speed': _config.speed.name,
      'reduceMotion': _config.reduceMotion,
      'duration': _config.duration.inMilliseconds,
      'specificAnimations': _config.specificAnimations,
    };
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    await updateConfig(AnimationConfig());
  }
}

// Helper functions for compute
Map<String, dynamic> _parseJson(String json) {
  return Map<String, dynamic>.from(
    const JsonDecoder().convert(json) as Map,
  );
}

String _stringifyJson(Map<String, dynamic> data) {
  return const JsonEncoder().convert(data);
}

// Animation widgets
class AnimatedListWidget extends StatefulWidget {
  final List<Widget> children;
  final AnimationType animationType;
  final Duration? duration;
  final bool staggered;
  final String? animationKey;

  const AnimatedListWidget({
    super.key,
    required this.children,
    this.animationType = AnimationType.fadeIn,
    this.duration,
    this.staggered = true,
    this.animationKey,
  });

  @override
  State<AnimatedListWidget> createState() => _AnimatedListWidgetState();
}

class _AnimatedListWidgetState extends State<AnimatedListWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? const Duration(milliseconds: 400),
      vsync: this,
    );

    if (widget.staggered) {
      _animations = List.generate(
        widget.children.length,
        (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              index * 0.1 / widget.children.length,
              1.0,
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
      );
    } else {
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _animations = List.filled(widget.children.length, animation);
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        widget.children.length,
        (index) => AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            switch (widget.animationType) {
              case AnimationType.fadeIn:
                return FadeTransition(
                  opacity: _animations[index],
                  child: widget.children[index],
                );
              case AnimationType.slideIn:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).animate(_animations[index]),
                  child: widget.children[index],
                );
              case AnimationType.scaleIn:
                return ScaleTransition(
                  scale: _animations[index],
                  child: widget.children[index],
                );
              default:
                return widget.children[index];
            }
          },
        ),
      ),
    );
  }
}
