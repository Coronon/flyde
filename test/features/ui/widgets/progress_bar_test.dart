import 'dart:async';

import 'package:test/test.dart';

import 'package:flyde/features/ui/render/widget.dart';
import 'package:flyde/features/ui/widgets/progress_bar.dart';

String _constructBar(int highlighted, int decent, int percent) =>
    '${''.padLeft(highlighted, '█')}${''.padLeft(decent, '▒')} | $percent%';

void main() {
  late State<double> progress;
  late ProgressBar bar;
  late int width;

  setUp(() {
    progress = State(0);
    width = 100;
    bar = ProgressBar(progress, width: width)
      ..line = 0
      ..updateRequestReceiver = StreamController<WidgetUpdateRequest>().sink;
  });

  test('Renders correct bar width on different states', () {
    expect(
      bar.render().trim(),
      equals(_constructBar(0, 100, 0)),
    );

    progress.value = 1;

    expect(
      bar.render().trim(),
      equals(_constructBar(100, 0, 100)),
    );

    progress.value = 0.5;

    expect(
      bar.render().trim(),
      equals(_constructBar(50, 50, 50)),
    );

    progress.value = 0.6;

    expect(
      bar.render().trim(),
      equals(_constructBar(60, 40, 60)),
    );
  });

  test('Renders correct bar on different display widths', () {
    width = 80;
    bar = ProgressBar(progress, width: width)
      ..line = 0
      ..updateRequestReceiver = StreamController<WidgetUpdateRequest>().sink;

    expect(
      bar.render().trim(),
      equals(_constructBar(0, 80, 0)),
    );

    progress.value = 1;

    expect(
      bar.render().trim(),
      equals(_constructBar(80, 0, 100)),
    );

    progress.value = 0.5;

    expect(
      bar.render().trim(),
      equals(_constructBar(40, 40, 50)),
    );

    progress.value = 0.6;

    expect(
      bar.render().trim(),
      equals(_constructBar(48, 32, 60)),
    );
  });
}
