import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// أدوات واجهة متقدمة (بدون حزم خارجية)
/// - create3DChart: رسم أعمدة ثلاثية الأبعاد بشكل إيزومتريك
/// - createInteractiveButton: زر تفاعلي مع hover + glow + morphing + مؤثرات جسيمات
/// - createHeatMap: خريطة حرارية بسيطة تعتمد نقاط كثافة داخل مساحة الودجت
class AdvancedUI {
  /// رسم مخطط أعمدة ثلاثي الأبعاد بسيط.
  /// values: قائمة القيم؛ إذا كانت null سيتم توليد أمثلة تلقائيًا.
  static Widget create3DChart({List<double>? values, double height = 240}) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: _ThreeDBarChart(values: values),
    );
  }

  /// زر تفاعلي مع:
  /// - تأثير hover (توهج)
  /// - morphing للحواف
  /// - جسيمات بسيطة عند الضغط
  static Widget createInteractiveButton({
    String text = 'زر تفاعلي',
    VoidCallback? onPressed,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  }) {
    return _InteractiveButton(
      text: text,
      onPressed: onPressed,
      padding: padding,
    );
  }

  /// خريطة حرارية تعتمد نقاط كثافة نسبية داخل الودجت.
  /// استخدم إحداثيات [0..1] داخل العرض/الارتفاع.
  static Widget createHeatMap({
    List<HeatPoint>? points,
    double intensityScale = 1.0,
    double height = 220,
  }) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: _HeatMap(
        points: points ?? HeatPoint.sampleData(),
        intensityScale: intensityScale,
      ),
    );
  }
}

// ===================== 3D Chart =====================

class _ThreeDBarChart extends StatelessWidget {
  const _ThreeDBarChart({this.values});

  final List<double>? values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = (values == null || values!.isEmpty)
        ? [12, 28, 18, 36, 24, 30, 40].map((e) => e.toDouble()).toList()
        : values!;

    return CustomPaint(
      painter: _ThreeDBarPainter(
        data: data,
        baseColor: theme.colorScheme.primary,
      ),
    );
  }
}

class _ThreeDBarPainter extends CustomPainter {
  _ThreeDBarPainter({required this.data, required this.baseColor});

  final List<double> data;
  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = (data.isEmpty ? 1.0 : data.reduce(math.max)).clamp(1.0, double.infinity);
    final barCount = data.length;
    final gap = 8.0;
    final barWidth = (size.width - gap * (barCount + 1)) / barCount;
    final chartBottom = size.height - 24;
    final depth = math.min(16.0, barWidth * 0.4); // عمق الإيزومتريك

    // محاور خفيفة
    final axisPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, chartBottom), Offset(size.width, chartBottom), axisPaint);

    for (int i = 0; i < barCount; i++) {
      final value = data[i];
      final h = (value / maxVal) * (chartBottom - 16);
      final left = gap + i * (barWidth + gap);
      final right = left + barWidth;
      final top = chartBottom - h;

      // ألوان الوجوه
      final front = baseColor;
      final rightFace = _shadeColor(baseColor, 0.75);
      final topFace = _shadeColor(baseColor, 1.15);

      // الوجه الأمامي
      final frontRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, h),
        const Radius.circular(4),
      );
      final frontPaint = Paint()..color = front;
      canvas.drawRRect(frontRect, frontPaint);

      // الوجه العلوي (مائل للأعلى يمينًا)
      final topPath = Path()
        ..moveTo(left, top)
        ..lineTo(right, top)
        ..lineTo(right + depth, top - depth)
        ..lineTo(left + depth, top - depth)
        ..close();
      canvas.drawPath(topPath, Paint()..color = topFace);

      // الوجه الأيمن
      final rightPath = Path()
        ..moveTo(right, top)
        ..lineTo(right, chartBottom)
        ..lineTo(right + depth, chartBottom - depth)
        ..lineTo(right + depth, top - depth)
        ..close();
      canvas.drawPath(rightPath, Paint()..color = rightFace);
    }
  }

  Color _shadeColor(Color c, double factor) {
    // factor > 1 للتفتيح، < 1 للتعتيم
    final hsl = HSLColor.fromColor(c);
    final l = (hsl.lightness * factor).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }

  @override
  bool shouldRepaint(covariant _ThreeDBarPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.baseColor != baseColor;
  }
}

// ===================== Interactive Button =====================

class _InteractiveButton extends StatefulWidget {
  const _InteractiveButton({
    required this.text,
    required this.onPressed,
    required this.padding,
  });

  final String text;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;

  @override
  State<_InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<_InteractiveButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _controller;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() {
        _tickParticles();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spawnParticles(Offset origin) {
    final rnd = math.Random();
    for (int i = 0; i < 22; i++) {
      final angle = rnd.nextDouble() * math.pi * 2;
      final speed = 40 + rnd.nextDouble() * 80;
      final vx = math.cos(angle) * speed;
      final vy = math.sin(angle) * speed;
      _particles.add(_Particle(
        position: origin,
        velocity: Offset(vx, vy),
        life: 1.0,
        color: Colors.amber.withOpacity(0.9),
        radius: 2 + rnd.nextDouble() * 3,
      ));
    }
    if (!_controller.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  void _tickParticles() {
    final dt = 1 / 60.0;
    for (final p in _particles) {
      // تباطؤ بسيط + جاذبية خفيفة
      p.velocity = p.velocity * 0.98 + const Offset(0, 24) * dt;
      p.position += p.velocity * dt;
      p.life -= 0.02;
    }
    _particles.removeWhere((p) => p.life <= 0);
    if (_particles.isEmpty) {
      _controller.stop();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final radius = Tween<double>(begin: 14, end: 28).transform(_hovered ? 1 : 0);
    final shadowColor = Colors.amberAccent.withOpacity(_hovered ? 0.6 : 0.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (d) {
          final box = context.findRenderObject() as RenderBox?;
          final local = box?.globalToLocal(d.globalPosition) ?? Offset.zero;
          _spawnParticles(local);
        },
        onTap: widget.onPressed,
        child: CustomPaint(
          painter: _ParticlesPainter(_particles),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple,
                  Colors.indigo.shade600,
                  Colors.blue.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 0),
                )
              ],
            ),
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(widget.text),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.color,
    required this.radius,
  });

  Offset position;
  Offset velocity;
  double life; // 1..0
  Color color;
  double radius;
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter(this.particles);

  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.plus;
    for (final p in particles) {
      paint.color = p.color.withOpacity((p.life).clamp(0.0, 1.0));
      canvas.drawCircle(p.position, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}

// ===================== Heat Map =====================

class HeatPoint {
  HeatPoint({required this.position, required this.intensity});

  /// موضع نسبي داخل الودجت: x,y ضمن [0..1]
  final Offset position;
  /// شدة النقطة (يفضل 0..1) ويمكن تجاوزها حسب intensityScale
  final double intensity;

  static List<HeatPoint> sampleData() {
    // نمط نقاط عشوائية للتجربة
    final rnd = math.Random(42);
    return List.generate(30, (i) {
      return HeatPoint(
        position: Offset(rnd.nextDouble(), rnd.nextDouble()),
        intensity: rnd.nextDouble(),
      );
    });
  }
}

class _HeatMap extends StatelessWidget {
  const _HeatMap({required this.points, required this.intensityScale});

  final List<HeatPoint> points;
  final double intensityScale;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: CustomPaint(
        painter: _HeatMapPainter(points: points, intensityScale: intensityScale),
      ),
    );
  }
}

class _HeatMapPainter extends CustomPainter {
  _HeatMapPainter({required this.points, required this.intensityScale});

  final List<HeatPoint> points;
  final double intensityScale;

  @override
  void paint(Canvas canvas, Size size) {
    // طبقة للدمج اللوني
    final paint = Paint();
    final layerRect = Offset.zero & size;
    canvas.saveLayer(layerRect, Paint());

    for (final p in points) {
      final center = Offset(p.position.dx * size.width, p.position.dy * size.height);
      final radius = 24.0 + 80.0 * (p.intensity * intensityScale).clamp(0.0, 2.0);

      paint.shader = ui.Gradient.radial(
        center,
        radius,
        [
          const Color(0x00FF0000), // شفاف
          const Color(0x66FF6A00),
          const Color(0xAAFFAA00),
          const Color(0xFFFFEE00),
          const Color(0xCCFF0000), // مركز حار
        ],
        [0.0, 0.45, 0.7, 0.88, 1.0],
      );
      canvas.drawCircle(center, radius, paint);
    }

    // تلوين نهائي (اختياري: مرشح ألوان خفيف)
    canvas.restore();

    // شبكة خفيفة لإيضاح الموضع
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += size.width / 10) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += size.height / 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeatMapPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.intensityScale != intensityScale;
  }
}
