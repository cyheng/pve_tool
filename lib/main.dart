import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pve_tool/page/pve_config.dart';
import 'package:pve_tool/page/vm_step.dart';
import 'package:pve_tool/repository/init.dart';

import 'api/Http.dart';
import 'model/config.dart';
import 'page/pve_step.dart';
import 'page/vm_config.dart';

void main() async {
  Http.init();
  await RepositoryInit.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return OKToast(
        position: ToastPosition.top,
        child: MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          onGenerateRoute: (RouteSettings settings) {
            if (settings.name == '/pve') {
              return MaterialPageRoute(
                  builder: (context) =>   PvePage(
                      config: settings.arguments as ServerConfig));
            }
            if (settings.name == '/vm_config') {
              return MaterialPageRoute(
                  builder: (context) =>   VmConfigPage(arguments: settings.arguments));
            }
            if (settings.name == '/vm') {
              return MaterialPageRoute(builder: (context) =>   VmPage(arguments: settings.arguments as VmServerConfig));
            }
            return MaterialPageRoute(builder: (context) => const ServerPage());
          },
        ));
  }
}
