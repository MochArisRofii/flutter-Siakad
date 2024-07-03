import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/appConfigurationCubit.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/utils/animationConfiguration.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();

  static Route route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const SplashScreen(),
    );
  }
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      context.read<AppConfigurationCubit>().fetchAppConfiguration();
    });
  }

  void navigateToNextScreen() {
    if (context.read<AuthCubit>().state is Unauthenticated) {
      Navigator.of(context).pushReplacementNamed(Routes.auth);
    } else {
      Navigator.of(context).pushReplacementNamed(
        (context.read<AuthCubit>().state as Authenticated).isStudent
            ? Routes.home
            : Routes.parentHome,
      );
    }
  }

  // void fetchAndSetUserProfile() {
  //   Future.delayed(Duration.zero, () {
  //     context.read<UserProfileCubit>().fetchAndSetUserProfile();
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AppConfigurationCubit, AppConfigurationState>(
        listener: (context, appConfigState) {
          if (appConfigState is AppConfigurationFetchSuccess) {
            navigateToNextScreen();
          }
        },
        builder: (context, appConfigState) {
          if (appConfigState is AppConfigurationFetchFailure) {
            return Center(
              child: ErrorContainer(
                onTapRetry: () {
                  context.read<AppConfigurationCubit>().fetchAppConfiguration();
                },
                errorMessageCode: appConfigState.errorMessage,
              ),
            );
          }

          return Center(
            child: Animate(
              effects: customItemZoomAppearanceEffects(
                delay: const Duration(
                  milliseconds: 10,
                ),
                duration: const Duration(
                  seconds: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: SvgPicture.asset(
                  Utils.getImagePath("appLogo.svg"),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
