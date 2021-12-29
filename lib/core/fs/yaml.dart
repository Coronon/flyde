import 'dart:math';

/// Encode the given value to a YAML formatted string
String encodeAsYaml(dynamic yaml) => _encodeAsYaml(yaml);

/// Encode the given value to a YAML formatted string
///
/// This internal function allows not exposing [depth],
/// which controlls the indentation level in this recursive
/// function, to the end user.
String _encodeAsYaml(dynamic yaml, {int depth = 0}) {
  if (yaml is String) {
    return _encodeString(yaml, depth);
  } else if (yaml is List) {
    throw UnimplementedError();
  } else if (yaml is Map) {
    throw UnimplementedError();
  } else {
    return yaml.toString();
  }
}

/// Encode [yaml] to YAML formatted string
///
/// This will take care of breaking up the string into
/// multiple parts if it is too long.
///
/// [depth] is the current depth in the YAML stream,
/// [skipQuote] will not quote the encoded string while
/// [skipBreakup] will prevent breaking up the string.
///
/// An extra indent can be specified to take the preceding
/// YAML key into account when deciding if the string should be split.
String _encodeString(
  String yaml,
  int depth, {
  bool skipQuote = false,
  bool skipBreakup = false,
  int extraIndent = 0,
}) {
  String encodedString = "";

  // Break up string if to long
  if (!skipBreakup && depth * indentWidth + extraIndent + yaml.length > maxLineLength) {
    encodedString += '"\\';

    // Escape all symbols now to avoid longer lines caused by escaped symbols
    yaml = yaml.escapeSymbols();

    int symbolsLeft = yaml.length;

    while (symbolsLeft > 0) {
      // Indent on new line
      encodedString += '\n' + _indent(depth + 1);

      // Compute substring range and update symbolsLeft
      final int substringStart = yaml.length - symbolsLeft;
      final int availableSpace = max(
        maxLineLengthExtension - 1,
        maxLineLength - ((depth + 1) * indentWidth) - 1, // -1 -> extra '\' at the end
      );
      // Get first candidate for substringLength
      final int substringLengthCandidate = min(
        availableSpace,
        symbolsLeft,
      );
      // If the last symbol is `\` we need to push it to the next line as it would escape our '\' at the line end
      final int substringLength = yaml[substringStart + substringLengthCandidate - 1] != '\\'
          ? substringLengthCandidate
          : substringLengthCandidate - 1;
      symbolsLeft -= substringLength;

      // Add encoded substring
      encodedString += _encodeString(
        yaml.substring(
          substringStart,
          substringStart + substringLength,
        ),
        depth,
        skipQuote: true, // We have outer quotes
        skipBreakup: true, // We already break up the string
        extraIndent: 1,
      );

      // Add '\' to wrap around
      if (symbolsLeft > 0) {
        encodedString += '\\';
      } else {
        encodedString += '"';
      }
    }
  } else {
    // No breaking up needed
    // Check if quotes are required
    if (!skipQuote && _shouldQuoteString(yaml)) {
      encodedString += '"${yaml.escapeSymbols()}"';
    } else {
      encodedString += yaml;
    }
  }

  return encodedString;
}

/// Determine if the string [yaml] should be placed
/// in double quotes e.g. `"$yaml"`
bool _shouldQuoteString(String yaml) {
  // Empty
  if (yaml.isEmpty) return true;
  // Starts with special char (YAML)
  if (yamlIndicators.contains(yaml[0])) return true;
  // Contains non ASCII symbols (or control symbols)
  if (!asciiCharString.hasMatch(yaml)) return true;

  return false;
}

/// Create a left padded string that matches the required
/// indentation at [depth] level.
///
/// The number of spaces per level is configured by [indentWidth].
String _indent(int depth) {
  return ''.padLeft(indentWidth * depth);
}

extension _EscapedSymbols on String {
  /// Escapes the `"`, `\n` and `\r` symbols
  /// for use in a YAML encoded string
  String escapeSymbols() => replaceAll('"', '\\"').replaceAll('\n', '\\n').replaceAll('\r', '\\r');
}

/// Matches all ASCII only strings that dont contain control symbols
final RegExp asciiCharString = RegExp(r'^[\x20-\x7E]+$');

/// List of symbols that are not allowed to start a YAML string without quotes
const List<String> yamlIndicators = [
  ' ',
  '-',
  '?',
  ':',
  ',',
  '[',
  ']',
  '{',
  '}',
  '#',
  '&',
  '*',
  '!',
  '|',
  '>',
  "'",
  '"',
  '%',
  '@',
  '`'
];

/// How many spaces each depth level should be indented
const int indentWidth = 2;

/// Maximum length a line might have
const int maxLineLength = 70;

/// Length of an extension on [maxLineLength] if
/// `depth * indentWidth > maxLineLength`
const int maxLineLengthExtension = 5;
