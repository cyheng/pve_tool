import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class PasswordForm extends StatefulWidget {
  final name;

  final label;

  final initialValue;

  final onSaved;

  const PasswordForm({super.key,required this.name ,this.label, this.initialValue,this.onSaved});

  @override
  State<PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  var obscureText = true;

  @override
  Widget build(BuildContext context) {
    return _buildPasswordField();
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: FormBuilderTextField(
        name: widget.name,
        onSaved: widget.onSaved,
        initialValue: widget.initialValue,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: widget.label,
          border: OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(Icons.visibility),
            onPressed: () {
              setState(() {
                obscureText = !obscureText;
              });
            },
          ),
        ),
      ),
    );
  }
}
