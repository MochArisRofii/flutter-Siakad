import 'dart:async';
import 'dart:io';

import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/examTabSelectionCubit.dart';
import 'package:eschool/cubits/examsOnlineCubit.dart';
import 'package:eschool/cubits/submitOnlineExamAnswersCubit.dart';
import 'package:eschool/data/models/answerOption.dart';
import 'package:eschool/data/models/question.dart';
import 'package:eschool/data/repositories/onlineExamRepository.dart';
import 'package:eschool/ui/screens/home/homeScreen.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:lottie/lottie.dart';
import 'package:wakelock/wakelock.dart';

import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';

import 'package:eschool/cubits/onlineExamQuestionsCubit.dart';
import 'package:eschool/ui/screens/exam/onlineExam/widgets/examQuestionStatusBottomSheetContainer.dart';
import 'package:eschool/ui/screens/exam/onlineExam/widgets/examTimerContainer.dart';
import 'package:eschool/ui/screens/exam/onlineExam/widgets/optionContainer.dart';
import 'package:eschool/ui/screens/exam/onlineExam/widgets/questionContainer.dart';

import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';

import 'package:eschool/data/models/examOnline.dart';

class ExamOnlineScreen extends StatefulWidget {
  final ExamOnline exam;
  const ExamOnlineScreen({Key? key, required this.exam}) : super(key: key);

  @override
  ExamOnlineScreenState createState() => ExamOnlineScreenState();
  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => BlocProvider(
        create: (context) =>
            SubmitOnlineExamAnswersCubit(OnlineExamRepository()),
        child: ExamOnlineScreen(
          exam: arguments['exam'],
        ),
      ),
    );
  }
}

class ExamOnlineScreenState extends State<ExamOnlineScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ExamTimerContainerState> timerKey =
      GlobalKey<ExamTimerContainerState>();
  late PageController pageController = PageController();

  bool isExitDialogOpen = false;
  bool isExamQuestionStatusBottomsheetOpen = false;
  bool isExamCompleted = false;
  bool isSubmissionInProgress = false;

  int currentQuestionIndex = 0;
  Map<int, List<int>> _selectedAnswersWithQuestionId = {};

  Timer? canGiveExamAgainTimer;
  bool canGiveExamAgain = true;

  int canGiveExamAgainTimeInSeconds = 5;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      timerKey.currentState?.startTimer();
    });

    Wakelock.enable();

    WidgetsBinding.instance.addObserver(this);

    if (Platform.isAndroid) {
      FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    canGiveExamAgainTimer?.cancel();
    Wakelock.disable();
    if (Platform.isAndroid) {
      FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    }
    super.dispose();
  }

  void setCanGiveExamTimer() {
    canGiveExamAgainTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (canGiveExamAgainTimeInSeconds == 0) {
        timer.cancel();

        //can give exam again false
        canGiveExamAgain = false;

        //show exam complete
        if (!isExamCompleted) submitExamAnswers();
        //submit only if not submitted before
      } else {
        canGiveExamAgainTimeInSeconds--;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      setCanGiveExamTimer();
    } else if (state == AppLifecycleState.resumed) {
      canGiveExamAgainTimer?.cancel();
      //if user can give exam again
      if (canGiveExamAgain) {
        canGiveExamAgainTimeInSeconds = 5;
      }
    }
  }

  void onBackPress() {
    isExitDialogOpen = true;
    if (!isExamCompleted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(
            Utils.getTranslatedLabel(context, quitExamKey),
          ),
          actions: [
            CupertinoButton(
              child: Text(
                Utils.getTranslatedLabel(context, yesKey),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onPressed: () {
                submitExamAnswers();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            CupertinoButton(
              child: Text(
                Utils.getTranslatedLabel(context, noKey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ).then((value) {
        isExitDialogOpen = false;
      });
    }
  }

  Widget buildOnlineExamAppbar(BuildContext context) {
    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarMediumtHeightPercentage,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomBackButton(onTap: onBackPress),
          Align(
            alignment: Alignment.topCenter,
            child: Text(
              widget.exam.subject?.getSubjectName() ?? "",
              style: TextStyle(
                color: Theme.of(context).scaffoldBackgroundColor,
                fontSize: Utils.screenTitleFontSize,
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 25.0),
              child: ExamTimerContainer(
                navigateToResultScreen: finishExamOnline,
                examDurationInMinutes: widget.exam.duration ?? 0,
                key: timerKey,
              ),
            ),
          ),
          Align(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.exam.title ?? "",
                  style: TextStyle(
                    color: Utils.getColorScheme(context).background,
                    fontSize: Utils.screenSubTitleFontSize,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Utils.getColorScheme(context).background,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Text(
                  "${widget.exam.totalMarks} ${Utils.getTranslatedLabel(context, marksKey)}",
                  style: TextStyle(
                    color: Utils.getColorScheme(context).background,
                    fontSize: Utils.screenSubTitleFontSize,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showExamQuestionStatusBottomSheet() {
    final submitOnlineExamAnswersCubit =
        context.read<SubmitOnlineExamAnswersCubit>();
    isExamQuestionStatusBottomsheetOpen = true;
    showModalBottomSheet(
      isScrollControlled: true,
      elevation: 5.0,
      context: context,
      isDismissible: !isSubmissionInProgress,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      builder: (context) {
        return ExamQuestionStatusBottomSheetContainer(
          submitOnlineExamAnswersCubit: submitOnlineExamAnswersCubit,
          onlineExamId: widget.exam.id ?? 0,
          submittedAnswers: _selectedAnswersWithQuestionId,
          navigateToResultScreen: finishExamOnline,
          pageController: pageController,
        );
      },
    );
    /*
    .then((value) {
      isExamQuestionStatusBottomsheetOpen = false;
    });
     */
  }

  void submitQuestionAnswer(Question question, AnswerOption answerOption) {
    List<int> submittedAnswerIds =
        _selectedAnswersWithQuestionId[question.id] ?? List<int>.from([]);

    //If thet total correct answer and submitted answer lenght is same then

    if (question.totalCorrectAnswer() == submittedAnswerIds.length) {
      if (submittedAnswerIds.length == (question.options ?? []).length) {
        return;
      }
      submittedAnswerIds.removeAt(0);
      submittedAnswerIds.add(answerOption.id ?? 0);
    } else {
      //submit the answer
      submittedAnswerIds.add(answerOption.id ?? 0);
    }

    _selectedAnswersWithQuestionId[question.id ?? 0] = submittedAnswerIds;

    setState(() {});
  }

  void submitExamAnswers() {
    context.read<SubmitOnlineExamAnswersCubit>().submitAnswers(
        examId: widget.exam.id ?? 0, answers: _selectedAnswersWithQuestionId);
  }

  void finishExamOnline() {
    Future.delayed(Duration.zero, () {
      timerKey.currentState?.cancelTimer();
    });

    if (isExamQuestionStatusBottomsheetOpen && !isSubmissionInProgress) {
      Navigator.of(context).pop();
    }
    if (isExitDialogOpen) {
      Navigator.of(context).pop();
    }
    if (!isExamCompleted) {
      submitExamAnswers();
    }
  }

  Widget buildBottomButton() {
    return Container(
      width: MediaQuery.of(context).size.width * (0.345),
      height: MediaQuery.of(context).size.height * (0.045),
      decoration: BoxDecoration(
        color: Utils.getColorScheme(context).primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: IconButton(
        onPressed: () {
          showExamQuestionStatusBottomSheet();
        },
        padding: EdgeInsets.zero,
        color: Utils.getColorScheme(context).background,
        highlightColor: Colors.transparent,
        icon: const Icon(
          Icons.keyboard_arrow_up_rounded,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildQuestions() {
    return BlocBuilder<OnlineExamQuestionsCubit, OnlineExamQuestionsState>(
      builder: (context, state) {
        if (state is OnlineExamQuestionsFetchSuccess) {
          return PageView.builder(
            onPageChanged: (index) {
              currentQuestionIndex = index;
              setState(() {});
            },
            controller: pageController,
            itemCount: state.questions.length,
            itemBuilder: (context, index) {
              final question = state.questions[index];
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: Utils.getScrollViewTopPadding(
                    context: context,
                    appBarHeightPercentage: Utils.appBarMediumtHeightPercentage,
                  ),
                  bottom: MediaQuery.of(context).size.height * 0.06,
                ),
                child: Column(
                  children: [
                    QuestionContainer(
                      questionColor: Utils.getColorScheme(context).secondary,
                      questionNumber: index + 1,
                      question: question,
                    ),
                    (question.totalCorrectAnswer() > 1)
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    "${Utils.getTranslatedLabel(context, noteKey)} ${Utils.getTranslatedLabel(context, selectKey)} ${question.totalCorrectAnswer()} ${Utils.getTranslatedLabel(context, examMultipleAnsNoteKey)}",
                                    style: TextStyle(
                                      color: Utils.getColorScheme(context)
                                          .onBackground,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                    const SizedBox(
                      height: 25,
                    ),
                    ...(question.options ?? [])
                        .map(
                          (option) => OptionContainer(
                            question: question,
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * (0.85),
                              maxHeight: MediaQuery.of(context).size.height *
                                  Utils.questionContainerHeightPercentage,
                            ),
                            answerOption: option,
                            submittedAnswerIds:
                                _selectedAnswersWithQuestionId[question.id] ??
                                    List<int>.from([]),
                            submitAnswer: submitQuestionAnswer,
                          ),
                        )
                        .toList(),
                  ],
                ),
              );
            },
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget buildExamCompleteDialog() {
    isExamCompleted = true;
    return Container(
      alignment: Alignment.center,
      color: Utils.getColorScheme(context).secondary.withOpacity(0.5),
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              "assets/animations/payment_success.json",
              animate: true,
            ),
            Text(
              Utils.getTranslatedLabel(context, examCompletedKey),
              textAlign: TextAlign.center,
              style: TextStyle(color: Utils.getColorScheme(context).secondary),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          CustomRoundedButton(
            backgroundColor: Utils.getColorScheme(context).primary,
            buttonTitle: Utils.getTranslatedLabel(context, homeKey),
            titleColor: Theme.of(context).scaffoldBackgroundColor,
            showBorder: false,
            widthPercentage: 0.3,
            height: 45,
            onTap: () {
              Navigator.of(context).pop();
              //goto 1st tab [Home] in bottomNavigatonbar
              Navigator.of(context).popUntil((route) => route.isFirst);
              HomeScreen.homeScreenKey.currentState!.changeBottomNavItem(0);
            },
          ),
          CustomRoundedButton(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            buttonTitle: Utils.getTranslatedLabel(context, resultKey),
            titleColor: Utils.getColorScheme(context).primary,
            showBorder: true,
            borderColor: Utils.getColorScheme(context).primary,
            widthPercentage: 0.3,
            height: 45,
            onTap: () {
              context.read<ExamsOnlineCubit>().getExamsOnline(
                  classSubjectId: context
                              .read<ExamTabSelectionCubit>()
                              .state
                              .examFilterByClassSubjectId ==
                          0
                      ? 0
                      : widget.exam.classSubjectId ?? 0,
                  childId: 0,
                  useParentApi: false);
              Navigator.pushReplacementNamed(
                context,
                Routes.resultOnline,
                arguments: {
                  "examId": widget.exam.id,
                  "examName": widget.exam.title,
                  "subjectName": widget.exam.subject?.getSubjectName() ?? "",
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (_) {
        onBackPress();
      },
      child: Scaffold(
        floatingActionButton: buildBottomButton(),
        //bottom center button
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniCenterDocked,
        body: Stack(
          children: [
            _buildQuestions(),
            buildOnlineExamAppbar(context),
            BlocConsumer<SubmitOnlineExamAnswersCubit,
                SubmitOnlineExamAnswersState>(
              listener: (context, state) {
                if (state is SubmitOnlineExamAnswersFailure) {
                  isSubmissionInProgress = false;
                  Utils.showCustomSnackBar(
                    context: context,
                    errorMessage: Utils.getErrorMessageFromErrorCode(
                      context,
                      state.errorMessage,
                    ),
                    backgroundColor: Utils.getColorScheme(context).error,
                  );
                }
                if (state is SubmitOnlineExamAnswersSuccess) {
                  isExamQuestionStatusBottomsheetOpen = true;
                  isSubmissionInProgress = false;
                }
                if (state is SubmitOnlineExamAnswersInProgress) {
                  isSubmissionInProgress = true;
                }
              },
              builder: (context, state) {
                if (state is SubmitOnlineExamAnswersSuccess) {
                  return buildExamCompleteDialog();
                }
                if (isSubmissionInProgress) {
                  return const Center(child: CircularProgressIndicator());
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
