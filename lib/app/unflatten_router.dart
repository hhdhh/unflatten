import 'package:go_router/go_router.dart';
import 'package:unflatten_studio/features/camera_lab/presentation/camera_lab_screen.dart';
import 'package:unflatten_studio/features/landing/presentation/landing_screen.dart';

final unflattenRouter = GoRouter(
  initialLocation: '/camera-lab',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingScreen(),
    ),
    GoRoute(
      path: '/camera-lab',
      builder: (context, state) => const CameraLabScreen(),
    ),
  ],
);
