import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Поле ввода кода подтверждения отдельными ячейками.
///
/// Внутри — один невидимый [TextField]: так работает автоподстановка кода
/// из SMS и вставка из буфера, чего не даёт набор из N отдельных полей.
/// Ячейки только отрисовывают его содержимое.
class CodeInput extends StatefulWidget {
  const CodeInput({
    super.key,
    required this.controller,
    required this.length,
    this.enabled = true,
    this.hasError = false,
    this.onCompleted,
  });

  final TextEditingController controller;
  final int length;
  final bool enabled;
  final bool hasError;

  /// Вызывается, когда набрана последняя цифра.
  final ValueChanged<String>? onCompleted;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    final text = widget.controller.text;
    if (text.length == widget.length) {
      widget.onCompleted?.call(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = widget.controller.text;

    return Stack(
      children: [
        // Невидимое настоящее поле: держит фокус, клавиатуру и автозаполнение.
        SizedBox(
          height: 56,
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              enabled: widget.enabled,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.enabled ? () => _focus.requestFocus() : null,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.length, (i) {
                final filled = i < text.length;
                final isNext = i == text.length && _focus.hasFocus;
                final border = widget.hasError
                    ? scheme.error
                    : isNext
                        ? scheme.primary
                        : scheme.outlineVariant;
                return Container(
                  width: 44,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: border,
                      width: isNext || widget.hasError ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    filled ? text[i] : '',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
