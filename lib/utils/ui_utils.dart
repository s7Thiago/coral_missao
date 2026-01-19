import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void customLauncher({
  required Widget target,
  required BuildContext context,
  bool opaque = false,
  bool maintainState = true,
  bool fullscreenDialog = false,
  bool barrierDismissible = true,
  Duration transitionDuration = const Duration(milliseconds: 550),
  Color barrierColor = Colors.black54,
  String? barrierLabel,
  Duration? reverseTransitionDuration,
  RouteSettings? settings,
  Widget Function(BuildContext, Animation<dynamic>, Animation<dynamic>, Widget)?
  transitionsBuilder,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: opaque,
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
      transitionDuration: transitionDuration,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      reverseTransitionDuration:
          reverseTransitionDuration ?? const Duration(milliseconds: 650),
      settings: settings,
      transitionsBuilder:
          transitionsBuilder ??
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return FadeTransition(opacity: animation, child: child);
          },
      pageBuilder: (ctx, _, __) {
        return target;
      },
    ),
  );
}

bool isKeyboardHidden(BuildContext context) =>
    MediaQuery.of(context).viewInsets.bottom == 0;

Future<String> get localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}
