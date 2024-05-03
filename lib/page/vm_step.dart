import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import '../api/Http.dart';
import '../mixin/ssh_terminal.dart';
import '../model/config.dart';

class VmPage extends StatefulWidget {
  const VmPage({super.key,this.arguments});
  final arguments;
  @override
  State<VmPage> createState() => _VmPageState();
}

class _VmPageState extends State<VmPage> {
  VmServerConfig get config => widget.arguments as VmServerConfig;

  late final terminal;
  String infoText = "虚拟机服务器执行中";
  late final SSHSession session;
  late final SSHClient client;
  bool isStarted = false;
  bool canNext = false;

  bool terminalControl = false;

  String terminalControlText = "控制台输入:关闭";

  @override
  void initState() {
    super.initState();
    initTerminal();
  }

  @override
  void dispose() {
    session.close();
    client.close();
    super.dispose();
  }

  Future<void> initTerminal() async {
    terminal = SSHTerminal(username: config.vmUsername, host: config.vmHost);
    terminal.writeLineWithPrompt('连接 ${config.vmHost} ...');
    client = SSHClient(
      await SSHSocket.connect(config.vmHost, int.parse(config.vmSSHPort)),
      username: config.vmUsername,
      onPasswordRequest: () => config.vmPassword,
    );

    terminal.writeLineWithPrompt('已连接');

    session = await client.shell(
      pty: SSHPtyConfig(
        width: terminal.viewWidth,
        height: terminal.viewHeight,
      ),
    );

    terminal.onResize = (width, height, pixelWidth, pixelHeight) {
      session.resizeTerminal(width, height, pixelWidth, pixelHeight);
    };
    session.stdout
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .listen(terminal.write);

    session.stderr
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .listen(terminal.write);
  }

  Future<void> onStarted() async {
    setState(() {
      isStarted = true;
    });
    terminal.buffer.clear();
    terminal.buffer.setCursor(0, 0);

    setState(() {
      isStarted = false;
      canNext = true;
    });
  }

  void turnOnTerminal() {
    setState(() {
      terminalControl = !terminalControl;
      terminalControlText = terminalControl ? "控制台输入:开启" : "控制台输入:关闭";
    });
    if (terminalControl) {
      terminal.onOutput = (data) {
        session.write(utf8.encode(data));
      };
    } else {
      terminal.onOutput = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(),
          const SizedBox(width: 8.0),
          Text(
            infoText,
            style: const TextStyle(fontSize: 20.0),
          ),
        ],
      )),
      body: Column(
        children: [
          Expanded(
            child: TerminalView(
              terminal,
              padding: const EdgeInsets.all(8.0),
            ),
          ),
          Center(
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: !isStarted ? onStarted : null,
                  child: const Text('开始'),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: turnOnTerminal,
                  child: Text(terminalControlText),
                  style: terminalControl
                      ? ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.redAccent))
                      : ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.grey)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Future<void> getRestoreStatus(uploadId) async {
    var response =
        await Http.dio.get("/api2/json/nodes/pve/tasks/$uploadId/status");
    int currentIdx = 0;
    int start = 0;
    int limit = 510;
    while (response.data['data']['status'] == 'running') {
      await Future.delayed(const Duration(seconds: 1));
      var logInfo = await Http.dio.get(
          "/api2/extjs/nodes/pve/tasks/$uploadId/log?start=$start&limit=510");
      int total = logInfo.data['total'];
      start = ((total / limit).truncate() * limit);
      Stream.fromIterable(logInfo.data['data'])
          .where((event) => event['n'] > currentIdx)
          .forEach((element) {
        terminal.writeLine("${element['n']}:${element['t']}");
        currentIdx = element['n'];
      });
      response =
          await Http.dio.get("/api2/json/nodes/pve/tasks/$uploadId/status");
    }
  }
}
