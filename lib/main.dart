import 'package:flutter/material.dart';
import 'package:notify/src/blocs/register/register_bloc.dart';
import 'package:notify/src/blocs/send_message/send_message_form.dart';
import 'package:notify/src/models/error_handler.dart';
import 'package:notify/src/ui/home.dart';
import 'package:notify/src/ui/register.dart';
import 'package:notify/src/ui/signin.dart';
import 'package:notify/src/ui/widgets/alert.dart';
import 'package:notify/src/ui/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';

// const String PARSE_APP_ID = 'iCYTGvNAatQe64smIVqoOidyKKoPx4N0qq3zdH2o';
// const String PARSE_APP_URL = 'https://parseapi.back4app.com';
// const String MASTER_KEY = 'lTkaAkYe0jKDFfFEpdWZmgs8jqQwBqwlQyDjKPBS';
// const String LIVE_QUERY_URL = 'wss://laleks.back4app.io';

const String CURRENT_RELEASE = 'version 0.1.6';

void main() async {
  runApp(
    RestartWidget(
      child: InitApp(),
    ),
  );
}

class InitApp extends StatefulWidget {
  @override
  _InitAppState createState() => _InitAppState();
}

class _InitAppState extends State<InitApp> {
  // ! executed during hot reload
  @protected
  @mustCallSuper
  void reassemble() async {
    super.reassemble();
    print('');
    print('======================== reassemble ==========================');
  }

  @override
  dispose() {
    print('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('++++++++++++++++++++++ InitAppState ++++++++++++++++++++++++++');
    return ChangeNotifierProvider(
      create: (context) => RegisterBloc(),
      child: MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  final _errorHandler = ErrorHandler.instance;
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // initialization of application made in two step, first one below,
    // the second in InitialData of StreamBuilder
    final _bloc = Provider.of<RegisterBloc>(context, listen: false);
    // _bloc.initData();
    _bloc.event.add(InitializeApp());
    return MaterialApp(
      title: 'Notify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF02BB9F),
        primaryColorDark: Color(0xFF167F67),
        accentColor: Color(0xFF167F67),
      ),
      home: StreamBuilder(
        stream: _bloc.appState,
        initialData: AppState.loading,
        builder: (BuildContext context, AsyncSnapshot<AppState> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            print('AppState Snapshot arrived: ${snapshot.data}');
            switch (snapshot.data) {
              case AppState.authenticated:
                _bloc.uiState = UIState.home;
                print(_bloc.uiState);
                return Home();

              case AppState.unauthenticated:
                _bloc.uiState = UIState.signin;
                print(_bloc.uiState);
                return Signin();

              case AppState.unregistred:
                return Register();
              case AppState.uninitialized:
                _bloc.uiState = UIState.zero;
                print(_bloc.uiState);
                return Home();

              case AppState.loading:
                _bloc.uiState = UIState.loading;
                print(_bloc.uiState);
                return LoadingIndicator();

              case AppState.sendMessageForm:
                _bloc.uiState = UIState.messageSendForm;
                print(_bloc.uiState);
                return SendForm();

              case AppState.error:
                _bloc.uiState = UIState.alertScreen;
                print(_bloc.uiState);
                return Alert(
                    message: _errorHandler.message,
                    revert: _errorHandler.revert);

              case AppState.reset:
                print('AppState.reset in main()');
                WidgetsBinding.instance.addPostFrameCallback(
                    (_) => RestartWidget.restartApp(context));
                ;
                _bloc.uiState = UIState.loading;
                print(_bloc.uiState);
                return LoadingIndicator();
            }
          }
          return Center(child: Text('Not Implemented'));
        },
      ),
    );
  }
}

class RestartWidget extends StatefulWidget {
  RestartWidget({this.child});

  final Widget child;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>().restartApp();
  }

  @override
  _RestartWidgetState createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    print('hhhhhhhhhhhh RestartApp() hhhhhhhhhhhhhhhh');
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    print('hhhhhhhhhhhh build RestartApp() hhhhhhhhhhhhhhhh');
    return KeyedSubtree(
      key: key,
      child: widget.child,
    );
  }
}
