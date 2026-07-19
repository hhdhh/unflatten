import 'package:go_router/go_router.dart';
import 'package:unflatten_studio/features/camera_lab/presentation/camera_lab_screen.dart';

final unflattenRouter = GoRouter(
  initialLocation: '/camera-lab',
  routes: [
    GoRoute(path: '/', redirect: (_, _) => '/camera-lab'),
    GoRoute(
      path: '/camera-lab',
      builder: (context, state) => const CameraLabScreen(),
    ),
  ],
);
