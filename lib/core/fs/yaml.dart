import 'dart:math';

/// Encode the given value to a YAML formatted string
String encodeAsYaml(dynamic yaml) => _encodeAsYaml(yaml);

/// Encode the given value to a YAML formatted string
///
/// This internal function allows not exposing [depth],
/// which controlls the indentation level in this recursive
/// function, to the end user.
String _encodeAsYaml(dynamic yaml, {int depth = 0, int extraIndent = 0}) {
  if (yaml is String) {
    return _encodeString(yaml, depth, extraIndent: extraIndent);
  } else if (yaml is List) {
    throw UnimplementedError();
  } else if (yaml is Map) {
    return _encodeMap(yaml, depth);
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
  String encodedString = '';

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

/// Encode [yaml] to YAML formatted key-value pairs
/// 
/// [depth] is the current depth in the YAML stream.
///
/// All keys have to be strings that match the RegExp [mapKey]
String _encodeMap(Map yaml, int depth) {
  String encodedMap = '';

  // Build key -> value pairs
  yaml.forEach((key, value) {
    // Key must be a string
    if (!_validateYAMLKey(key)) throw ArgumentError("Invalid YAML key '$key'");

    // We need to indent maps to form a hierarchy
    final int valueDepth = value is Map ? depth + 1 : depth;
    // For a valid hierarchy nested maps need to be properly indented on a new line
    final String keyValueSeperator = value is Map ? ':\n' + _indent(valueDepth) : ': ';
    // {indent}{key}: {value} -> key + 2(': ') is extra indent
    final int extraIndent = value is Map ? 0 : (key as String).length + 2;

    // key: value
    // otherKey:
    //   nestedKey: nestedValue
    encodedMap += _indent(depth) +
        key +
        keyValueSeperator +
        _encodeAsYaml(
          value,
          depth: valueDepth,
          extraIndent: extraIndent,
        ) +
        '\n';
  });

  // Remove possible trailing '\n'
  return encodedMap.trim();
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

/// Check whether the provided [key] is
/// a valid YAML key (not strict to spec)
/// and can be used
bool _validateYAMLKey(dynamic key) {
  // Key type not supported
  if (key is! String) {
    return false;
  }
  // Invalid format
  if (!mapKey.hasMatch(key)) {
    return false;
  }

  return true;
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

final RegExp mapKey = RegExp(r'^[a-zA-Z_$!.#+*~][[a-zA-Z0-9_$!.#+*~]*$');

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
