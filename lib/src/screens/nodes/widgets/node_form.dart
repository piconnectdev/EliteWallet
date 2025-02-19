import 'package:elite_wallet/core/node_address_validator.dart';
import 'package:elite_wallet/core/node_port_validator.dart';
import 'package:elite_wallet/src/widgets/base_text_form_field.dart';
import 'package:elite_wallet/src/widgets/standard_checkbox.dart';
import 'package:elite_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:ew_core/node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:elite_wallet/generated/i18n.dart';
import 'package:mobx/mobx.dart';

class NodeForm extends StatelessWidget {
  NodeForm({
    required this.nodeViewModel,
    required this.formKey,
    this.editingNode,
  })  : _addressController = TextEditingController(text: editingNode?.uri.host.toString()),
        _portController = TextEditingController(text: editingNode?.uri.port.toString()),
        _loginController = TextEditingController(text: editingNode?.login),
        _passwordController = TextEditingController(text: editingNode?.password) {
    if (editingNode != null) {
      nodeViewModel
        ..setAddress((editingNode!.uri.host.toString()))
        ..setPort((editingNode!.uri.port.toString()))
        ..setPassword((editingNode!.password ?? ''))
        ..setLogin((editingNode!.login ?? ''))
        ..setSSL((editingNode!.isSSL))
        ..setTrusted((editingNode!.trusted));
    }
    if (nodeViewModel.hasAuthCredentials) {
      reaction((_) => nodeViewModel.login, (String login) {
        if (login != _loginController.text) {
          _loginController.text = login;
        }
      });

      reaction((_) => nodeViewModel.password, (String password) {
        if (password != _passwordController.text) {
          _passwordController.text = password;
        }
      });
    }

    _addressController.addListener(() => nodeViewModel.address = _addressController.text);
    _portController.addListener(() => nodeViewModel.port = _portController.text);
    _loginController.addListener(() => nodeViewModel.login = _loginController.text);
    _passwordController.addListener(() => nodeViewModel.password = _passwordController.text);
  }

  final NodeCreateOrEditViewModel nodeViewModel;
  final GlobalKey<FormState> formKey;
  final Node? editingNode;

  final TextEditingController _addressController;
  final TextEditingController _portController;
  final TextEditingController _loginController;
  final TextEditingController _passwordController;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: BaseTextFormField(
                  controller: _addressController,
                  hintText: S.of(context).node_address,
                  validator: NodeAddressValidator(),
                ),
              )
            ],
          ),
          SizedBox(height: 10.0),
          Row(
            children: <Widget>[
              Expanded(
                  child: BaseTextFormField(
                controller: _portController,
                hintText: S.of(context).node_port,
                keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
                validator: NodePortValidator(),
              ))
            ],
          ),
          SizedBox(height: 10.0),
          if (nodeViewModel.hasAuthCredentials) ...[
            Row(
              children: <Widget>[
                Expanded(
                    child: BaseTextFormField(
                  controller: _loginController,
                  hintText: S.of(context).login,
                ))
              ],
            ),
            SizedBox(height: 10.0),
            Row(
              children: <Widget>[
                Expanded(
                    child: BaseTextFormField(
                  controller: _passwordController,
                  hintText: S.of(context).password,
                ))
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Observer(
                    builder: (_) => StandardCheckbox(
                      value: nodeViewModel.useSSL,
                      onChanged: (value) => nodeViewModel.useSSL = value,
                      caption: S.of(context).use_ssl,
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Observer(
                    builder: (_) => StandardCheckbox(
                      value: nodeViewModel.trusted,
                      onChanged: (value) => nodeViewModel.trusted = value,
                      caption: S.of(context).trusted,
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}
