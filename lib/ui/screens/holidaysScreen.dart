import 'package:eschool/cubits/holidaysCubit.dart';
import 'package:eschool/data/repositories/systemInfoRepository.dart';
import 'package:eschool/ui/widgets/holidaysContainer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HolidaysScreen extends StatelessWidget {
  final int? childId;
  const HolidaysScreen({Key? key, this.childId}) : super(key: key);

  static Route route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => BlocProvider<HolidaysCubit>(
        create: (context) => HolidaysCubit(SystemRepository()),
        child: HolidaysScreen(
          childId: routeSettings.arguments as int?,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HolidaysContainer(
        childId: childId,
      ),
    );
  }
}
