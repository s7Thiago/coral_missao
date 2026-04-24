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
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                filterQuality: FilterQuality.high,
                scale: Tween<double>(begin: 0.8, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOutCirc,
                  ),
                ),
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOutCirc,
                        ),
                      ),
                  child: child,
                ),
              ),
            );
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

void customLauncherHero({
  required Widget target,
  required BuildContext context,
  required Rect originRect,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (_, __, ___) => target,
      transitionsBuilder: (_, animation, __, child) {
        return _GrowTransition(
          animation: animation,
          originRect: originRect,
          child: child,
        );
      },
    ),
  );
}

Rect? getWidgetGlobalRect(BuildContext context) {
  final renderObject = context.findRenderObject();

  if (renderObject == null || renderObject is! RenderBox) {
    return null;
  }

  final renderBox = renderObject;

  if (!renderBox.hasSize) {
    return null;
  }

  final position = renderBox.localToGlobal(Offset.zero);
  final size = renderBox.size;

  return position & size;
}

class _GrowTransition extends StatelessWidget {
  final Animation<double> animation;
  final Rect originRect;
  final Widget child;

  const _GrowTransition({
    required this.animation,
    required this.originRect,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);

    final rectTween = RectTween(
      begin: originRect,
      end: Rect.fromLTWH(0, 0, screenSize.width, screenSize.height),
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final rect = rectTween.evaluate(curved)!;

        return Stack(
          children: [
            Positioned.fromRect(
              rect: rect,
              child: ClipRRect(
                borderRadius: BorderRadius.circular((1 - curved.value) * 16),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}
