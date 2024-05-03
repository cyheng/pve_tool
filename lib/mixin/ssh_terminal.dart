import 'package:xterm/xterm.dart';

mixin SSHTerminalMixin on Terminal {
  void writeLine(String text) {
    write('$text\r\n');
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
