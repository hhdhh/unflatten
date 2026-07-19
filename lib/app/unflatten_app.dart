import 'package:flutter/material.dart';
import 'package:unflatten_studio/app/unflatten_router.dart';
import 'package:unflatten_studio/core/theme/unflatten_theme.dart';

class UnflattenApp extends StatelessWidget {
  const UnflattenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Unflatten Studio',
      debugShowCheckedModeBanner: false,
      theme: buildUnflattenTheme(),
      routerConfig: unflattenRouter,
    );
  }
}
