import 'package:go_router/go_router.dart';
import 'package:unflatten_studio/features/camera_lab/presentation/camera_lab_screen.dart';
import 'package:unflatten_studio/features/landing/presentation/landing_screen.dart';
import 'package:unflatten_studio/features/mix_lab/presentation/mix_lab_screen.dart';
import 'package:unflatten_studio/features/my_recipes/presentation/my_recipes_screen.dart';

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
    GoRoute(
      path: '/mix-lab',
      builder: (context, state) => const MixLabScreen(),
    ),
    GoRoute(
      path: '/my-recipes',
      builder: (context, state) => const MyRecipesScreen(),
    ),
  ],
);
