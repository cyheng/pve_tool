import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pve_tool/component/form.dart';

import '../api/Http.dart';
import '../component/dropdown.dart';
import '../component/password.dart';
import '../model/config.dart';
import '../model/constants.dart';

class ServerPage extends StatefulWidget {
  const ServerPage({super.key});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  ServerConfig config = ServerConfig();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: buildConfigForm(),
      ),
    );
  }

  buildConfigForm() {
    return FormBuilder(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPveColumn(),
              const SizedBox(width: 16.0),
              _buildNasColumn(),
            ],
          ),
          const SizedBox(height: 16.0),
          _buildButtons()
        ],
      ),
    );
  }

  Expanded _buildPveColumn() {
    return Expanded(
      child: FormUtils.buildColumn('PVE', [
        FormUtils.buildTextFormField(ServerConfigKeys.pveHost,
            label: 'Host',
            initialValue: config.pveHost,
            validator: FormUtils.hostValidator, onSaved: (val) {
          config.pveHost = val;
        }),
        FormUtils.buildTextFormField(ServerConfigKeys.pveSSHPort,
            label: 'SSH Port',
            initialValue: config.pveSSHPort.toString(),
            keyboardType: TextInputType.number,
            valueTransformer: (val) => int.tryParse(val),
            validator: FormUtils.portValidator, onSaved: (val) {
          config.pveSSHPort = val;
        }),
        FormUtils.buildTextFormField(ServerConfigKeys.pveHttpsPort,
            label: 'HTTPS Port',
            initialValue: config.pveHttpsPort.toString(),
            keyboardType: TextInputType.number,
            valueTransformer: (val) => num.tryParse(val),
            validator: FormUtils.portValidator, onSaved: (val) {
          config.pveHttpsPort = val;
        }),
        FormUtils.buildTextFormField(ServerConfigKeys.pveUsername,
            label: 'Username',
            initialValue: config.pveUsername, onSaved: (val) {
          config.pveUsername = val;
        }),
        PasswordForm(
          name: ServerConfigKeys.pvePassword,
          label: 'Password',
          initialValue: config.pvePassword,
          onSaved: (val) {
            config.pvePassword = val;
          },
        ),
        ConfigDropDownWidget(
          serverConfig: config,
          validator: () => _formKey.currentState!.validate(),
          onConfigChanged: (config) {
            setState(() {
              this.config = config;
              _formKey.currentState?.patchValue(config.toJson());
            });
          },
        ),
      ]),
    );
  }

  Expanded _buildNasColumn() {
    return Expanded(
      child: FormUtils.buildColumn('NAS', [
        FormUtils.buildTextFormField(ServerConfigKeys.nasHost,
            label: 'Nas Host',
            initialValue: config.nasHost,
            validator: FormUtils.hostValidator, onSaved: (val) {
          config.nasHost = val;
        }),
        FormUtils.buildTextFormField(ServerConfigKeys.nasUsername,
            label: 'Nas Username',
            initialValue: config.nasUsername, onSaved: (val) {
          config.nasUsername = val;
        }),
        PasswordForm(
          name: ServerConfigKeys.nasPassword,
          label: 'Password',
          initialValue: config.nasPassword,
          onSaved: (val) {
            config.nasPassword = val;
          },
        ),
        FormUtils.buildTextFormField(ServerConfigKeys.nasStorage,
            label: 'Storage ID',
            initialValue: config.nasStorage, onSaved: (val) {
          config.nasStorage = val;
        }),
        FormUtils.buildTextFormField(ServerConfigKeys.nasShare,
            label: '共享文件夹名', initialValue: config.nasShare, onSaved: (val) {
          config.nasShare = val;
        }),
        FormUtils.buildTextFormField(ServerConfigKeys.nasImageArchive,
            label: '镜像备份名',
            initialValue: config.nasImageArchive, onSaved: (val) {
          config.nasImageArchive = val;
        }),
        FormUtils.buildTextFormField(ServerConfigKeys.nasImageName,
            label: '镜像名', initialValue: config.nasImageName, onSaved: (val) {
          config.nasImageName = val;
        }),
      ]),
    );
  }

  _handleSubmitBtn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    Map<String, dynamic> data = {
      'username': config.pveApiUsername,
      'password': config.pvePassword,
    };
    Http.dio.options.baseUrl = config.pveApiUrl;
    Response response = await Http.dio.post(
      '/api2/json/access/ticket',
      data: data,
    );
    var CSRFPreventionToken = response.data['data']['CSRFPreventionToken'];
    var ticket = response.data['data']['ticket'];
    Http.dio.options.headers['Csrfpreventiontoken'] = CSRFPreventionToken;
    Http.dio.options.headers['Cookie'] = 'PVEAuthCookie=$ticket';
    showToast('登录成功');
    Navigator.pushNamed(context, '/pve', arguments: config);
  }

  Center _buildButtons() {
    return Center(
      child: ElevatedButton(
        onPressed: _handleSubmitBtn,
        child: const Text('下一步'),
      ),
    );
  }
}
