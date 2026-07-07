import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_iot/injections.dart' as di;
import 'package:mobile_iot/main.dart';
import 'package:mobile_iot/shared/application/locale_cubit.dart';
import 'package:mobile_iot/shared/application/session_cubit.dart';

void main() {
  testWidgets('Login screen renders', (WidgetTester tester) async {
    await di.init();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: di.serviceLocator<SessionCubit>()),
          BlocProvider.value(value: di.serviceLocator<LocaleCubit>()),
        ],
        child: const MobileIotApp(),
      ),
    );
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
