import 'package:flutter_bloc/flutter_bloc.dart';

class Observer extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    print("Create :: $bloc");
    super.onCreate(bloc);
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    print("Event :: $event");
    super.onEvent(bloc, event);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    print(change);
    super.onChange(bloc, change);
  }

  @override
  void onClose(BlocBase bloc) {
    print("Close :: $bloc");
    super.onClose(bloc);
  }
}
