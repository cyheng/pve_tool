import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import '../api/Http.dart';
import '../mixin/ssh_terminal.dart';
import '../model/config.dart';

class PvePage extends StatefulWidget {
  const PvePage({super.key,required this.config});
  final ServerConfig config ;
  @override
  State<PvePage> createState() => _PvePageState();
}

class _PvePageState extends State<PvePage> {

  ServerConfig get config => widget.config;

  late final SSHTerminal terminal ;

  String infoText = "pve 服务器执行中";
  late final SSHSession session;
  late final SSHClient client;
  bool isStarted = false;
  bool canNext = false;

  bool terminalControl = false;

  String terminalControlText = "控制台输入:关闭";

  final vmId = 201;
  String vmHost = "";

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
    
    terminal = SSHTerminal(username: config.pveUsername, host: config.pveHost);
    terminal.writeLineWithPrompt('连接 ${config.pveHost} ...');
    client = SSHClient(
      await SSHSocket.connect(config.pveHost, int.parse(config.pveSSHPort)),
      username: config.pveUsername,
      onPasswordRequest: () => config.pvePassword,
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
    await removeLocalLvm();
    await addSmb();
    await updateLocal();
    var copyFuture = copyIsoToLocal();
    var backupFuture = restoreBackup();
    await Future.wait([copyFuture, backupFuture]);
    await startVm();
    await removeSmb();
    await findVmIpAddress();
    setState(() {
      isStarted = false;
      canNext = true;
    });
  }

  Future<void> restoreBackup() async {
    

    terminal.writeLineWithPrompt("开始还原备份");
    var response = await Http.dio.post("/api2/extjs/nodes/pve/qemu", data: {
      'vmid': vmId,
      'force': 0,
      'unique': 1,
      'start': 0,
      'archive': config.backupArchive,
    });
    String result = "${response.requestOptions.method} ${response.realUri}";
    terminal.writeLine(result);
    terminal.writeLineWithPrompt(response.data.toString().replaceAll("\n", ""));
    var uploadId = response.data?['data'];
    if (uploadId != null) {
      await getRestoreStatus(uploadId);
    }
    terminal.writeLineWithPrompt("还原备份完成");
  }

  Future<void> copyIsoToLocal() async {
    

    terminal.writeLineWithPrompt("正在从 nas 拷贝镜像到 pve local 卷");
    var cmd =
        "rsync -avP ${config.mountIsoPath}/${config.nasImageName} ${config.pveIsoPath}  ";
    terminal.writeLineWithPrompt(cmd);
    var session = await client.execute(
      cmd,
      pty: SSHPtyConfig(
        width: terminal.viewWidth,
        height: terminal.viewHeight,
      ),
    );
    final stdoutDone = Completer<void>();
    final stderrDone = Completer<void>();

    session.stdout.listen(
      (data) {
        var msg = utf8.decode(data).replaceAll("\n", "\r\n");
        terminal.write(msg);
      },
      onDone: stdoutDone.complete,
      onError: stderrDone.completeError,
    );

    session.stderr.listen(
      (data) {
        var msg = utf8.decode(data).replaceAll("\n", "\r\n");
        terminal.write(msg);
      },
      onDone: stderrDone.complete,
      onError: stderrDone.completeError,
    );

    await stdoutDone.future;
    await stderrDone.future;
    terminal.writeLineWithPrompt("拷贝完成");
  }

  Future<void> addSmb() async {
    

    terminal.writeLineWithPrompt("正在添加 smb 存储");
    var response = await Http.dio.post("/api2/extjs/storage", data: {
      'storage': config.nasStorage,
      'server': config.nasHost,
      'username': config.nasUsername,
      'password': config.nasPassword,
      'share': config.nasShare,
      'content': ['images', 'iso', 'vztmpl', 'backup', 'rootdir', 'snippets'],
      'type': 'cifs',
      'disable': 0,
    });
    String result = "${response.requestOptions.method} ${response.realUri}";
    terminal.writeLineWithPrompt(result);
    terminal.writeLine(response.data.toString().replaceAll("\n", ""));
    terminal.writeLineWithPrompt("添加 smb 存储成功");
  }

  Future<void> removeSmb() async {
    terminal.writeLineWithPrompt("正在移除 smb 存储");
    var response = await Http.dio.delete("/api2/extjs/storage//nas");
    String result = "${response.requestOptions.method} ${response.realUri}";
    terminal.writeLineWithPrompt(result);
    terminal.writeLine(response.data.toString().replaceAll("\n", ""));
    terminal.writeLineWithPrompt("移除 smb 存储成功");
  }

  Future<void> updateLocal() async {
    terminal.writeLineWithPrompt("正在调整 local 存储存放内容");
    await Future.delayed(const Duration(seconds: 1));
    Map<String, Map<String, dynamic>> storeMap = await getCurrentStore();
    var digest = storeMap['local']?['digest'];
    print(digest);
    var response = await Http.dio.put("/api2/extjs/storage/local", data: {
      'content': ['backup', 'iso', 'vztmpl', 'images', 'rootdir', 'snippets'],
      'shared': 0,
      'delete': [
        'preallocation',
        'max-protected-backups',
        'prune-backups',
        'maxfiles'
      ],
      'disable': 0,
      'digest': digest,
    });
    String result = "${response.requestOptions.method} ${response.realUri}";
    terminal.writeLineWithPrompt(result);
    terminal.writeLine(response.data.toString().replaceAll("\n", ""));
    terminal.writeLineWithPrompt("调整 local 存储存放内容成功");
  }

  Future<Map<String, Map<String, dynamic>>> getCurrentStore() async {
    terminal.writeLineWithPrompt("正在获取当前存储...");

    var storeData = await Http.dio.get('/api2/json/storage');
    String result = "${storeData.requestOptions.method} ${storeData.realUri}";
    terminal.writeLineWithPrompt(result);
    Map<String, Map<String, dynamic>> storeMap =
        await Stream.fromIterable(storeData.data['data']).fold({},
            (previous, element) {
      previous[element['storage']] = {
        'digest': element['digest'],
        'content': element['content'],
        'path': element['path'],
        'shared': element['shared'],
      };
      return previous;
    });

    terminal.writeLine("当前存储有：${storeMap.keys} ");
    return storeMap;
  }

  Future<void> removeLocalLvm() async {
    terminal.writeLineWithPrompt("正在删除 local-lvm ");
    List<String> cmds = [
      "lvremove -y  pve/data",
      "lvextend -l +100%FREE -r pve/root"
    ];
    for (var cmd in cmds) {
      terminal.writeLineWithPrompt(cmd);
      var result = await client.run(cmd);
      String sout = utf8.decode(result).replaceAll("\n", "");
      terminal.writeLine(sout);
    }
    var response = await Http.dio.delete("/api2/extjs/storage//local-lvm");
    String result = "${response.requestOptions.method} ${response.realUri}";
    terminal.writeLineWithPrompt(result);
    terminal.writeLine(response.data.toString().replaceAll("\n", ""));

    terminal.writeLineWithPrompt("删除 local-lvm 成功");
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
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal,
                  ),
                  onPressed: canNext
                      ? () {
                          Navigator.of(context).pushNamed('/vm_config',
                              arguments: {'vmHost': vmHost});
                        }
                      : null,
                  child: const Text('下一步'),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: turnOnTerminal,
                  style: terminalControl
                      ? ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.redAccent))
                      : ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.grey)),
                  child: Text(terminalControlText),
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
        terminal.writeLine("Restore INFO:${element['t']}");
        currentIdx = element['n'];
      });
      response =
          await Http.dio.get("/api2/json/nodes/pve/tasks/$uploadId/status");
    }
  }

  findVmIpAddress() async {
    
    terminal.writeLineWithPrompt("正在查找虚拟机 ip 地址");
    var cmd = "rm -f /etc/apt/sources.list.d/pve-enterprise.list && sed -i 's|http://ftp.debian.org/debian|http://mirrors.tuna.tsinghua.edu.cn/debian|g' /etc/apt/sources.list && apt update && apt-get install -y net-tools fping";
    terminal.writeLineWithPrompt(cmd);
    var installResult = await client.run(cmd);
    String sout = utf8.decode(installResult).replaceAll("\n", "\r\n");
    terminal.writeLine(sout);
    await client.run(cmd);
    vmHost = await getVmHostUsingArp(cmd);
    for (var i = 0; i < 5; i++) {
      if (vmHost.isNotEmpty) {
        break;
      }
      cmd = "fping -g ${config.pveHost}/24";
      terminal.writeLineWithPrompt(cmd);
      await client.run(cmd);
      vmHost = await getVmHostUsingArp(cmd);
    }
    if (vmHost.isEmpty) {
      terminal.writeLineWithPrompt("未找到 ip 地址,可能虚拟机没有连网");
      return;
    }
    terminal.writeLineWithPrompt("虚拟机 ip 地址为: $vmHost");
  }

  Future<String> getVmHostUsingArp(String cmd) async {
    cmd =
        "qm config $vmId | grep -oP 'virtio=\\K[^,]+' | awk -F',' '{print tolower(\$1)}'";
    terminal.writeLineWithPrompt(cmd);
    String macAddrResult =
        utf8.decode(await client.run(cmd)).replaceAll("\n", "");
    terminal.writeLine(macAddrResult);
    cmd =
        "arp -an | awk '/'\"$macAddrResult\"'/ { print \$2 }' | sed 's/(\\(.*\\))/\\1/g'";
    terminal.writeLineWithPrompt(cmd);
    return utf8.decode(await client.run(cmd)).replaceAll("\n", "");
  }

  startVm() async {
    terminal.writeLineWithPrompt("正在启动虚拟机");
    var response =
        await Http.dio.post("/api2/extjs/nodes/pve/qemu/$vmId/status/start");
    String result = "${response.requestOptions.method} ${response.realUri}";
    terminal.writeLineWithPrompt(result);
    terminal.writeLine(response.data.toString().replaceAll("\n", ""));
    terminal.writeLineWithPrompt("启动虚拟机成功");
  }
}
