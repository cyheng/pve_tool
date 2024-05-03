import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class FormUtils {
  static Column buildColumn(String title, List<Widget> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        ...fields,
      ],
    );
  }

  static hostValidator(String? value) {
    if (value == null ||
        value.isEmpty ||
        !RegExp(r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$').hasMatch(value)) {
      return '请输入有效IP地址';
    }
    return null;
  }

  static portValidator(String? value) {
    if (value == null || value.isEmpty || int.tryParse(value) == null) {
      return '请输入有效端口号';
    }
    return null;
  }

  static notNullValidator(String? value) {
    if (value == null || value.isEmpty) {
      return '值不能为空';
    }
    return null;
  }

  static Widget buildTextFormField(String name,
      {label, initialValue, validator, onSaved,valueTransformer,keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: FormBuilderTextField(
        name: name,
        initialValue: initialValue,
        valueTransformer: valueTransformer,
        keyboardType: keyboardType,
        onSaved: onSaved,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (validator != null) {
            return validator(value);
          }
          return notNullValidator(value);
        },
      ),
    );
  }
}
