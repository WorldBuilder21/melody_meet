import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReusableTextFormField extends StatefulWidget {
  final TextInputType? textInputType;
  final TextStyle? suffixTextStyle;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final String? errorText;
  final int?
  maxLength; // specifies the maximum number of characters allowed, default is 255
  final bool?
  showCounter; // specifies if the counter should be shown, default is true
  final bool? obscureText;
  final TextEditingController? controller;
  final Function? functionValidate;
  final TextInputAction? textInputAction;
  final Function? onSubmitField;
  final int? maxLines;
  final Function? onFieldTap;
  final String? initialValue;
  final Function? onSavedFunc;
  final Function? onChangedFunc;
  final String? labelText;
  final String? suffixText;
  final String? preffixText;
  final TextStyle? preffixTextStyle;
  final List<TextInputFormatter>? inputFormatter;
  final bool? enabled;
  const ReusableTextFormField({
    super.key,
    this.textInputType,
    this.hintText,
    this.enabled,
    this.prefixIcon,
    this.inputFormatter,
    this.showCounter = true,
    this.suffixIcon,
    this.preffixText,
    this.preffixTextStyle,
    this.focusNode,
    this.errorText,
    this.suffixTextStyle,
    this.obscureText,
    this.controller,
    this.labelText,
    this.functionValidate,
    this.textInputAction,
    this.onSubmitField,
    this.maxLines,
    this.suffixText,
    this.onFieldTap,
    this.initialValue,
    this.onSavedFunc,
    this.onChangedFunc,
    this.maxLength = 255,
  });

  @override
  State<ReusableTextFormField> createState() => _ReusableTextFormFieldState();
}

class _ReusableTextFormFieldState extends State<ReusableTextFormField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      inputFormatters: widget.inputFormatter,
      cursorColor: Colors.black, // Changed to green
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      enabled: widget.enabled,
      obscureText: widget.obscureText!,
      keyboardType: widget.textInputType,
      textInputAction: widget.textInputAction,
      focusNode: widget.focusNode,
      initialValue: widget.initialValue,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      controller: widget.controller,
      onFieldSubmitted: widget.onSubmitField as void Function(String)?,
      validator: widget.functionValidate as String? Function(String?)?,
      onSaved: widget.onSavedFunc as void Function(String?)?,
      onChanged: widget.onChangedFunc as void Function(String)?,
      style: const TextStyle(color: Colors.black, height: 1),
      decoration: InputDecoration(
        counterText: widget.showCounter != true ? '' : null,
        labelText: widget.labelText,
        labelStyle: TextStyle(
          color:
              widget.focusNode?.hasFocus == true ? Colors.blue : Colors.black,
        ),
        errorText: widget.errorText,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
        prefixIcon:
            widget.prefixIcon != null
                ? IconTheme(
                  data: IconThemeData(
                    color:
                        widget.focusNode?.hasFocus == true
                            ? Colors.blue
                            : Colors.grey,
                  ),
                  child: widget.prefixIcon!,
                )
                : null,
        suffixIcon:
            widget.suffixIcon != null
                ? IconTheme(
                  data: IconThemeData(
                    color:
                        widget.focusNode?.hasFocus == true
                            ? Colors.blue
                            : Colors.grey,
                  ),
                  child: widget.suffixIcon!,
                )
                : null,
        hintText: widget.hintText,
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(10.0),
        ),
        suffixText: widget.suffixText,
        suffixStyle: widget.suffixTextStyle,
        prefixText: widget.preffixText,
        prefixStyle: widget.preffixTextStyle,
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(10.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(10.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Colors.blue,
          ), // Changed to green and made border thicker
          borderRadius: BorderRadius.circular(10.0),
        ),
        hintStyle: const TextStyle(fontSize: 14.0, color: Colors.grey),
      ),
    );
  }
}
