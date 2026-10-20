import 'package:flutter/material.dart';

class ProjectProgressChart extends StatelessWidget {
  const ProjectProgressChart({
    super.key,
    required this.values,
    required this.labels,
    this.title = 'Project Progress',
  });

  final List<double> values;
  final List<String> labels;
  final String title;

  @override
  Widget build(BuildContext context) {
    assert(values.length == labels.length);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: CustomPaint(
                painter: _LineChartPainter(values),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                    top: 12,
                    bottom: 24,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: labels
                        .map(
                          (e) => Text(
                        e,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
                      ),
                    )
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const left = 28.0;
    const top = 12.0;
    const bottom = 32.0;
    const right = 12.0;

    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    final grid = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = top + chartHeight * i / 4;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        grid,
      );
    }

    final axis = Paint()
      ..color = Colors.grey.shade500
      ..strokeWidth = 1.2;

    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + chartHeight),
      axis,
    );

    canvas.drawLine(
      Offset(left, top + chartHeight),
      Offset(size.width - right, top + chartHeight),
      axis,
    );

    final line = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = Colors.blue.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final point = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final path = Path();
    final area = Path();

    for (int i = 0; i < values.length; i++) {
      final x = left +
          (chartWidth / (values.length - 1).clamp(1, 999)) * i;

      final y = top +
          chartHeight -
          (values[i].clamp(0, 100) / 100) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
        area.moveTo(x, top + chartHeight);
        area.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        area.lineTo(x, y);
      }
    }

    area.lineTo(
      left + chartWidth,
      top + chartHeight,
    );
    area.close();

    canvas.drawPath(area, fill);
    canvas.drawPath(path, line);

    for (int i = 0; i < values.length; i++) {
      final x = left +
          (chartWidth / (values.length - 1).clamp(1, 999)) * i;

      final y = top +
          chartHeight -
          (values[i].clamp(0, 100) / 100) * chartHeight;

      canvas.drawCircle(Offset(x, y), 4.5, point);

      final tp = TextPainter(
        text: TextSpan(
          text: values[i].round().toString(),
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(x - tp.width / 2, y - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}