import '../../../core/console/terminal_color.dart';
import '../../ui/widgets/label.dart';
import '../../ui/widgets/line.dart';
import '../../ui/widgets/progress_bar.dart';
import '../../ui/widgets/spacer.dart';
import '../../ui/render/widget.dart';

/// The view for the screen that shows the progress of the build.
///
/// The view displays the number of [updatedFiles], the [progress] as a [ProgressBar], a [timer] of the elapsed time and
/// a custom [label] which displays further information about the state.
List<Widget> buildingView(
  State<String> updatedFiles,
  State<double> progress,
  State<String> label,
  State<TerminalColor> labelColor,
  State<String> timer,
) {
  return [
    Line(
      [Label.constant('Updated Files:'), Label.fixedStyle(updatedFiles, bold: true)],
      Label.constant(''),
      width: 16,
    ),
    Line(
      [Label.constant('Elapsed Time:'), Label.fixedStyle(timer, bold: true)],
      Label.constant(''),
      width: 16,
    ),
    Spacer(1),
    Label(label, color: labelColor, bold: State(true)),
    ProgressBar(progress),
  ];
}
