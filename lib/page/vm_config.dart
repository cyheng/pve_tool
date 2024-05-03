import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:pve_tool/model/constants.dart';

import '../component/form.dart';
import '../component/password.dart';
import '../model/config.dart';

class VmConfigPage extends StatefulWidget {
  const VmConfigPage({super.key,this.arguments});
  final arguments;
  @override
  State<VmConfigPage> createState() => _VmConfigPageState();
}

class _VmConfigPageState extends State<VmConfigPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  VmServerConfig config = VmServerConfig();

  @override
  Widget build(BuildContext context) {
    config.vmHost = widget.arguments['vmHost'];
    return Scaffold(
      appBar: AppBar(
          title: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "虚拟机配置",
            style: TextStyle(fontSize: 20.0),
          ),
        ],
      )),
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
              _buildVmColumn(),
              const SizedBox(width: 16.0),
              _buildVpnColumn(),
            ],
          ),
          const SizedBox(height: 16.0),
          _buildButtons()
        ],
      ),
    );
  }

  _buildVmColumn() {
    return Expanded(
      child: FormUtils.buildColumn('VM', [
        FormUtils.buildTextFormField(VmServerConfigKeys.vmHost,
            label: 'VM Host',
            initialValue: config.vmHost,
            validator: FormUtils.hostValidator, onSaved: (val) {
          config.vmHost = val;
        }),
        FormUtils.buildTextFormField(VmServerConfigKeys.vmSSHPort,
            label: 'VM SSH Port',
            initialValue: config.vmSSHPort.toString(),
            valueTransformer: (val) => int.tryParse(val),
            validator: FormUtils.portValidator, onSaved: (val) {
          config.vmSSHPort = val;
        }),
        FormUtils.buildTextFormField(VmServerConfigKeys.vmUsername,
            label: 'VM Username',
            initialValue: config.vmUsername, onSaved: (val) {
          config.vmUsername = val;
        }),
        PasswordForm(
          name: VmServerConfigKeys.vmPassword,
          label: 'Password',
          initialValue: config.vmPassword,
          onSaved: (val) {
            config.vmPassword = val;
          },
        ),
        FormUtils.buildTextFormField(VmServerConfigKeys.vmHospitalName,
            label: '交付医院',
            initialValue: config.vmHospitalName.toString(), onSaved: (val) {
          config.vmHospitalName = val;
        }),
      ]),
    );
  }

  _buildVpnColumn() {
    return Expanded(
      child: FormUtils.buildColumn('VPN', [
        FormUtils.buildTextFormField(VmServerConfigKeys.vpnUsername,
            label: 'VPN用户名', initialValue: config.vpnUsername, onSaved: (val) {
          config.vpnUsername = val;
        }),
        PasswordForm(
          name: VmServerConfigKeys.vpnPassword,
          label: 'VPN密码',
          initialValue: config.vpnPassword,
          onSaved: (val) {
            config.vpnPassword = val;
          },
        ),
        PasswordForm(
          name: VmServerConfigKeys.vpnSharedKey,
          label: 'VPN预共享密钥',
          initialValue: config.vpnSharedKey,
          onSaved: (val) {
            config.vpnSharedKey = val;
          },
        ),
      ]),
    );
  }

  _buildButtons() {
    return Center(
      child: FilledButton(
        onPressed: _handleSubmitBtn,
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.blueAccent)),
        child: const Text('下一步'),
      ),
    );
  }

  void _handleSubmitBtn() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    Navigator.pushNamed(context, '/vm', arguments: config);
  }
}
