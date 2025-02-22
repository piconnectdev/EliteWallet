import 'package:flutter/material.dart';
import 'package:elite_wallet/generated/i18n.dart';

class TextFieldListRow extends StatelessWidget {
  TextFieldListRow(
      {required this.title,
        required this.value,
        this.titleFontSize = 14,
        this.valueFontSize = 16,
        this.onSubmitted})
    : _textController = TextEditingController() {
    _textController.text = value;
  }

  final String title;
  final String value;
  final double titleFontSize;
  final double valueFontSize;
  final Function(String value)? onSubmitted;
  final TextEditingController _textController;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.background,
      child: Padding(
        padding:
        const EdgeInsets.only(left: 24, top: 16, bottom: 16, right: 24),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title,
                  style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .primaryTextTheme!
                          .labelSmall!
                          .color!),
                  textAlign: TextAlign.left),
              TextField(
                controller: _textController,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.done,
                maxLines: null,
                textAlign: TextAlign.start,
                style: TextStyle(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.w500,
                    color:
                        Theme.of(context).primaryTextTheme!.titleLarge!.color!),
                decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.only(top: 12, bottom: 0),
                    hintText: S.of(context).enter_your_note,
                    hintStyle: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context)
                            .primaryTextTheme!
                            .labelSmall!
                            .color!),
                    border: InputBorder.none),
                onSubmitted: (value) => onSubmitted?.call(value),
              )
            ]),
      ),
    );
  }
}
