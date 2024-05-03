import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pve_tool/model/config.dart';
import 'package:pve_tool/repository/repository.dart';

class ConfigDropDownWidget extends StatefulWidget {
  final ServerConfig serverConfig;
  final Function(ServerConfig) onConfigChanged;
  final bool Function() validator;

  const ConfigDropDownWidget(
      {super.key,
      required this.serverConfig,
      required this.validator,
      required this.onConfigChanged});

  @override
  State<ConfigDropDownWidget> createState() => _DropDownWidgetState();
}

class _DropDownWidgetState extends State<ConfigDropDownWidget> {
  String currentKey = StorageRepository.defaultKey;
  ServerConfigRepository serverConfigRepository = ServerConfigRepository();
  List<String> serverConfigKeys = [StorageRepository.defaultKey];
  TextEditingController _addConfigController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initServerConfig();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('选择配置:'),
        const SizedBox(width: 16.0),
        DropdownButton<String>(
          value: currentKey,
          onChanged: (String? newValue) async {
            var config = await serverConfigRepository.get(newValue!);
            widget.onConfigChanged(config!);
            setState(() {
              currentKey = newValue;
            });
          },
          items: serverConfigKeys.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(
              onPressed: onPressedAdd,
              child: Text('新增'),
              style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.blue)), // 设置按钮颜色
            ),
            SizedBox(width: 8.0), // 为按钮之间添加间隔
            FilledButton(
              onPressed: onPressedSave,
              child: Text('保存'),
              style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.green)), // 设置按钮颜色
            ),
            SizedBox(width: 8.0), // 为按钮之间添加间隔
            FilledButton(
              onPressed: onPressedDelete,
              child: Text('删除'),
              style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.red)), // 设置按钮颜色
            ),
          ],
        )
      ],
    );
  }

  initServerConfig() async {
    var keys = await serverConfigRepository.getAllKeys();
    setState(() {
      serverConfigKeys = keys;
      if (!serverConfigKeys.contains(currentKey)) {
        currentKey = serverConfigKeys.isNotEmpty
            ? serverConfigKeys.first
            : StorageRepository.defaultKey;
      }
    });
  }

  Future<void> onPressedDelete() async {
    if (currentKey == StorageRepository.defaultKey) {
      showErrorDialog('默认配置不能删除');
      return;
    }
    if (serverConfigKeys.length == 1) {
      showErrorDialog('至少保留一个配置');
      return;
    }

    // 确认删除弹框
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('删除配置'),
          content: Text('确认删除配置 $currentKey ?'),
          actions: [
            TextButton(
              onPressed: () async {
                await serverConfigRepository.remove(currentKey);
                await initServerConfig();
                var config = await serverConfigRepository.get(currentKey);
                widget.onConfigChanged(config!);
                showToast("删除成功");
                Navigator.of(context).pop();
              },
              child: Text('确认'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
          ],
        );
      },
    );
  }

  void showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('错误'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                // 关闭弹窗
                Navigator.of(context).pop();
              },
              child: Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  void onPressedAdd() {
    if (!widget.validator()) {
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('新建配置'),
          content: TextFormField(
            controller: _addConfigController,
            decoration: const InputDecoration(hintText: '请输入配置名称'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String text = _addConfigController.text;
                if (text.isEmpty) {
                  showToast("配置名称不能为空");
                  return;
                } else if (serverConfigKeys.contains(text)) {
                  showToast("配置名称已存在");
                  return;
                }
                await serverConfigRepository.save(text, widget.serverConfig);
                await initServerConfig();
                setState(() {
                  currentKey = text;
                });
                showToast("新增成功");
                Navigator.of(context).pop();
              },
              child: Text('保存'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  Future<void> onPressedSave() async {
    if (!widget.validator()) {
      return;
    }
    await serverConfigRepository.save(currentKey, widget.serverConfig);
    showToast("保存成功");
  }
}
