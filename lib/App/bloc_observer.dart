import 'package:bloc/bloc.dart';
import 'package:horseandriderscompanion/Utilities/app_logger.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    AppLogger.debug(
      LogCategory.bloc,
      '${bloc.runtimeType} event: ${event.runtimeType}',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    AppLogger.error(
      LogCategory.bloc,
      '${bloc.runtimeType} error',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    AppLogger.debug(
      LogCategory.bloc,
      '${bloc.runtimeType}: ${transition.currentState.runtimeType} -> '
      '${transition.nextState.runtimeType}',
    );
  }
}
