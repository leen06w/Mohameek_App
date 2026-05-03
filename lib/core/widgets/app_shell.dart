import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final bool scrollable;
  final EdgeInsets padding;
  final Color? backgroundColor;

  final String? title;
  final VoidCallback? onNotificationTap;
  final bool showDefaultAppBar;
  final bool showNotificationIcon;
  final bool showMenuIcon;

  const AppShell({
    super.key,
    required this.child,
    this.appBar,
    this.drawer,
    this.bottomNavigationBar,
    this.scrollable = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    this.backgroundColor,
    this.title,
    this.onNotificationTap,
    this.showDefaultAppBar = false,
    this.showNotificationIcon = true,
    this.showMenuIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 448),
      child: scrollable
          ? SingleChildScrollView(
              padding: padding,
              child: child,
            )
          : Padding(
              padding: padding,
              child: child,
            ),
    );

    PreferredSizeWidget? resolvedAppBar = appBar;

    if (resolvedAppBar == null && showDefaultAppBar) {
      resolvedAppBar = AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: showNotificationIcon
            ? IconButton(
                onPressed: onNotificationTap ?? () {},
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                ),
              )
            : null,
        title: Text(
          title ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (showMenuIcon && drawer != null)
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: resolvedAppBar,
      drawer: drawer,
      body: Center(child: content),
      bottomNavigationBar: bottomNavigationBar == null
          ? null
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: bottomNavigationBar!,
              ),
            ),
    );
  }
}