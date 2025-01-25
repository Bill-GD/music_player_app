import 'package:flutter/material.dart';

import '../globals/utils.dart';

class ActionDialog extends StatefulWidget {
  final Icon? icon;
  final String title;
  final double titleFontSize;
  final String? textContent;
  final Widget? widgetContent;
  final double contentFontSize;
  final bool centerContent;
  final List<Widget> actions;
  final Duration time;
  final Alignment scaleAlignment;
  final double? horizontalPadding;
  final bool barrierDismissible;
  final bool allowScroll;

  const ActionDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.titleFontSize,
    required this.textContent,
    required this.widgetContent,
    required this.contentFontSize,
    required this.centerContent,
    required this.actions,
    required this.time,
    required this.scaleAlignment,
    required this.horizontalPadding,
    required this.barrierDismissible,
    required this.allowScroll,
  });

  @override
  State<ActionDialog> createState() => _ActionDialogState();

  static Future<T?> static<T>(
    BuildContext context, {
    Icon? icon,
    required String title,
    required double titleFontSize,
    String? textContent,
    Widget? widgetContent,
    required double contentFontSize,
    bool centerContent = true,
    List<Widget> actions = const [],
    required Duration time,
    Alignment scaleAlignment = Alignment.center,
    double? horizontalPadding,
    bool barrierDismissible = true,
    bool allowScroll = false,
  }) async {
    assert(textContent != null || widgetContent != null, 'textContent or widgetContent parameter must be non-null');
    return await showGeneralDialog<T>(
      context: context,
      transitionDuration: time,
      barrierDismissible: barrierDismissible,
      barrierLabel: '',
      transitionBuilder: (_, anim1, __, child) {
        return _scaleTransition(anim1, scaleAlignment, child);
      },
      pageBuilder: (_, __, ___) {
        return _dialog(
          context,
          icon: icon,
          title: title,
          titleFontSize: titleFontSize,
          textContent: textContent,
          widgetContent: widgetContent,
          contentFontSize: contentFontSize,
          centerContent: centerContent,
          actions: actions,
          time: time,
          scaleAlignment: scaleAlignment,
          horizontalPadding: horizontalPadding,
          barrierDismissible: barrierDismissible,
          allowScroll: allowScroll,
        );
      },
    );
  }

  static Future<T?> stateful<T>(
    BuildContext context, {
    Icon? icon,
    required String title,
    required double titleFontSize,
    String? textContent,
    Widget? widgetContent,
    required double contentFontSize,
    bool centerContent = true,
    List<Widget> actions = const [],
    required Duration time,
    Alignment scaleAlignment = Alignment.center,
    double? horizontalPadding,
    bool barrierDismissible = true,
    bool allowScroll = false,
  }) async {
    assert(textContent != null || widgetContent != null, 'textContent or widgetContent parameter must be non-null');
    return await Navigator.push(
      context,
      RawDialogRoute(
        transitionDuration: time,
        barrierDismissible: barrierDismissible,
        barrierLabel: '',
        transitionBuilder: (_, anim1, __, child) {
          return _scaleTransition(anim1, scaleAlignment, child);
        },
        pageBuilder: (context, __, ___) {
          return ActionDialog(
            icon: icon,
            title: title,
            titleFontSize: titleFontSize,
            textContent: textContent,
            widgetContent: widgetContent,
            contentFontSize: contentFontSize,
            centerContent: centerContent,
            actions: actions,
            time: time,
            scaleAlignment: scaleAlignment,
            horizontalPadding: horizontalPadding,
            barrierDismissible: barrierDismissible,
            allowScroll: allowScroll,
          );
        },
      ),
    );
  }
}

class _ActionDialogState extends State<ActionDialog> {
  @override
  Widget build(BuildContext context) {
    return _dialog(
      context,
      icon: widget.icon,
      title: widget.title,
      titleFontSize: widget.titleFontSize,
      textContent: widget.textContent,
      widgetContent: widget.widgetContent,
      contentFontSize: widget.contentFontSize,
      centerContent: widget.centerContent,
      actions: widget.actions,
      time: widget.time,
      scaleAlignment: widget.scaleAlignment,
      horizontalPadding: widget.horizontalPadding,
      barrierDismissible: widget.barrierDismissible,
      allowScroll: widget.allowScroll,
    );
  }
}

ScaleTransition _scaleTransition(Animation<double> anim1, Alignment scaleAlignment, Widget child) {
  return ScaleTransition(
    scale: anim1.drive(CurveTween(curve: Curves.easeOutQuart)),
    alignment: scaleAlignment,
    child: child,
  );
}

AlertDialog _dialog(
  BuildContext context, {
  Icon? icon,
  required String title,
  required double titleFontSize,
  String? textContent,
  Widget? widgetContent,
  required double contentFontSize,
  bool centerContent = true,
  List<Widget> actions = const [],
  required Duration time,
  Alignment scaleAlignment = Alignment.center,
  double? horizontalPadding,
  bool barrierDismissible = true,
  bool allowScroll = false,
}) {
  final content = textContent != null
      ? Text(
          dedent(textContent),
          textAlign: centerContent ? TextAlign.center : null,
        )
      : widgetContent!;
  return AlertDialog(
    icon: icon,
    title: Text(
      title,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      maxLines: 4,
    ),
    titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: titleFontSize,
          fontWeight: FontWeight.w700,
        ),
    content: allowScroll ? SingleChildScrollView(child: content) : content,
    contentTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: contentFontSize,
        ),
    contentPadding: const EdgeInsets.only(left: 20, right: 20, top: 15),
    actionsAlignment: MainAxisAlignment.spaceEvenly,
    actions: actions,
    actionsPadding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      side: BorderSide(color: Theme.of(context).colorScheme.onSurface),
    ),
    insetPadding: EdgeInsets.only(
      left: horizontalPadding ?? 40,
      right: horizontalPadding ?? 40,
      top: 40,
      bottom: 16,
    ),
  );
}
