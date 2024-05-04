import 'package:xterm/xterm.dart';

enum Color {
  defaultColor,
  red,
  green,
  blue,
  yellow,
}

mixin SSHTerminalMixin on Terminal {
  void writeLine(String text) {
    write('$text\r\n');
  }

  void writeLineWithColor(String text, Color color) {
    switch (color) {
      case Color.defaultColor:
        writeLine(text);
        break;
      case Color.red:
        writeLine('\u001b[31m$text\u001b[0m');
        break;
      case Color.green:
        writeLine('\u001b[32m$text\u001b[0m');
        break;
      case Color.blue:
        writeLine('\u001b[34m$text\u001b[0m');
        break;
      case Color.yellow:
        writeLine('\u001b[33m$text\u001b[0m');
        break;
    }
  }

}

class SSHTerminal extends Terminal with SSHTerminalMixin {
  final String username;
  final String host;

  SSHTerminal({required this.username, required this.host});

  void writeLineWithPrompt(String text) {
    writeLine('$username@$host:~# $text');
  }
}
