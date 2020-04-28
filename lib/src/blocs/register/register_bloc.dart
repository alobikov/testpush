import 'dart:async';
import 'package:device_id/device_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notify/src/models/addressees.dart';
import 'package:notify/src/models/error_handler.dart';
import 'package:notify/src/models/message.dart';
import 'package:notify/src/services/back4app.dart';
import 'package:notify/utils/connection_status.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
// import 'package:notify/src/services/create_object.dart';

part 'register_event.dart';
part 'register_state.dart';

enum AppState {
  uninitialized,
  authenticated,
  unauthenticated,
  unknownEDA,
  unregistred,
  sendMessageForm,
  loading,
  error,
  reset,
}
enum UIState {
  home,
  messageSendForm,
  loading,
  signin,
  zero,
  alertScreen,
  introduce
}

class RegisterBloc extends ChangeNotifier {
  final _msg = Messages.instance;
  // final _msgToSend = MessageToSend();
  final _b4a = ParseService();
  final _addressees = Addressees();
  final _errorHandler = ErrorHandler.instance;
  final registerFormFields;
  RegisterInitFields initFields;
  UIState uiState;
  var _liveQuery;
  bool showRegister = true;
  bool showHome = false;
  String emailError;
  bool isOffline = false;

  StreamSubscription _connectionChangeStream;

  ConnectionStatusSingleton connectionStatus =
      ConnectionStatusSingleton.getInstance();

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  StreamController _appStateCtrl = StreamController<AppState>();
  Stream<AppState> get appState => _appStateCtrl.stream;
  StreamSink<AppState> get _inState => _appStateCtrl.sink;

  StreamController _initFormStateCtrl = StreamController<String>.broadcast();
  Stream<String> get initiateState => _initFormStateCtrl.stream;
  StreamSink<String> get initiateForm => _initFormStateCtrl.sink;

  StreamController _regFormStateCtrl = StreamController<Map<String, dynamic>>();
  Stream<Map<String, dynamic>> get formState => _regFormStateCtrl.stream;
  StreamSink<Map<String, dynamic>> get inForm => _regFormStateCtrl.sink;

  StreamController _regFormEventCtrl = StreamController<RegisterEvent>();
  StreamSink<RegisterEvent> get event => _regFormEventCtrl.sink;
  RegisterFormFields get getFormFields => registerFormFields;

  // ! Register Bloc constructor
  RegisterBloc() : registerFormFields = RegisterFormFields() {
    print('!!!!!!!  Register block constructor invoked !!!!!!!!!');

    _regFormEventCtrl.stream.listen(_mapEventController);

    /// this stream is used to inform about internet connectivity changes
    _connectionChangeStream =
        connectionStatus.connectionChange.listen(connectionChanged);

    /// this stream used to receive data from TextFormFields
    formState.listen((form) {
      print('formState in Bloc received: $form');
      registerFormFields.setField(form);
      print('Current state of RegFormFields ${registerFormFields.show()}');
    });
  }

  void _mapEventController(event) async {
    //***************************************/
    //* Populate Register/Signin form by mock user date
    if (event is PopulateFormEvent) {
      print('Populate button event');
      registerFormFields.setField(RegisterInitFields.getAll);
      RegisterInitFields.advanceToNextUser();
      print('RegisterFormFields: ${registerFormFields.show()}');
      notifyListeners();
      return;
      //
      //***************************************/
      //* Register User event handler
    } else if (event is SubmitFormEvent) {
      _inState.add(AppState.loading);
      // print('Submitted Register Form ${_registerFormFields.show()}');
      //* create account at BACK4APP if failed display error in AlertDialog
      await _b4a.logout(_liveQuery); //! but first make sure user not logged in
      _liveQuery = null;
      _msg.clear(); // clear local message repository
      final error = await _b4a.registerWith(registerFormFields);
      if (error != null) {
        // Alert() is common usage UI and it needs additional information
        // The revert point is one of this
        // We using ErrorHandler singleton to pass extra information
        _errorHandler.revertEvent = SwitchToRegisterEvent();
        _errorHandler.message = error;
        _inState.add(AppState.error);
      } else {
        // read all messages from server to local repository
        await _initMessageHandler();
        // subscribe to LiveQuery on 'Messages'
        _liveQuery ??= await _b4a.initiateLiveQuery(
            registerFormFields.name, _msg, _regFormEventCtrl.sink,
            mark: '1');
        _inState.add(AppState.authenticated); // show Home()
      }
      return;
    } else if (event is SigninFormEvent) {
      //***************************************/
      //* SignIn event handler - Signin button pressed
      print('**********SignInFormEvent ');
      _inState.add(AppState.loading);
      _msg.clear(); // clear local message repository
      var error = await _b4a.loginWith(registerFormFields);
      if (error != null) {
        print("Login failed");
        // Alert() is common usage UI and it needs additional information
        // The revert point is one of this
        // We using ErrorHandler singleton to pass extra information
        _errorHandler.revertEvent = SwitchToSigninEvent();
        _errorHandler.message = error;
        _inState.add(AppState.error);
      } else {
        // read all messages from server to local repository
        await _initMessageHandler();
        // subscribe to LiveQuery on 'Messages'
        _liveQuery ??= await _b4a.initiateLiveQuery(
            registerFormFields.name, _msg, _regFormEventCtrl.sink,
            mark: '2');
        // and generate event via provided sink
        _inState.add(AppState.authenticated); // showHome()
      }
      return;
      //
      //***************************************/
      //* Navigate to SendMessageForm
    } else if (event is SendMessageFormEvent) {
      String deviceid = await DeviceId.getID;
      print('^^^^^^^^^^^^^^^^^^^^^^ DeviceID: $deviceid');
      // await _b4a.getAllUsers();
      _inState.add(AppState.sendMessageForm);
      return;
      //
      //***************************************/
      //* SignOut event handler
    } else if (event is UserLogoutEvent) {
      _inState.add(AppState.loading);
      await _b4a.logout(_liveQuery); // liveQUery must be unsubscribed
      _liveQuery = null;
      initData(); // show Signin()
      return;

      //**************************************/
      //* toggle Register UI to Signin UI
    } else if (event is SwitchToSigninEvent) {
      _inState.add(AppState.unauthenticated);
      return;
    } else if (event is SwitchToRegisterEvent) {
      _inState.add(AppState.unregistred);
      return;
      //
      //**************************************/
      //* Application Initializing
    } else if (event is InitializeApp) {
      print('Register Bloc: Application Initializing');
      initData();
      return;

      //**************************************/
      //* New Message from server receive handling
    } else if (event is NewMessage) {
      //!  duplicated
      print('RegisterBloc: New message event');
      String title = 'From: ${event.msg.from} @ ${event.msg.timestamp}';
      await _showNotification(title, event.msg.body);
      _inState.add(AppState.authenticated); // redraw Home() with new message
      return;

      //**************************************/
      //* Return to Home Screen event handling
    } else if (event is NavigateToHomeEvent) {
      print('@@@@@@@@@@@@@@@ NavigateToHomeEvent Handler @@@@@@@@@@@@@@@@@@');
      if (_b4a.isEda) {
        // iniation of EDA60K user environment takes place here
        _msg.clear(); // clear local message repository
        await _initMessageHandler();
        _liveQuery ??= await _b4a.initiateLiveQuery(
            registerFormFields.name, _msg, _regFormEventCtrl.sink,
            mark: '3');
      }
      _inState.add(AppState.authenticated);
    }
    return;
  }

  String getFormFieldFor(String field) {
    return registerFormFields.getField(field);
  }

  initData() async {
    Future.delayed(Duration(seconds: 12)).then((_) {
      print('---------------- Network Waiting Timeout -----------------');
      checkOnNetworkTimeout();
    });

    // ! initializing of LocalNotification service
    var initializationSettingsAdndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = IOSInitializationSettings();
    var initializationSettings = InitializationSettings(
        initializationSettingsAdndroid, initializationSettingsIOS);

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    bool res = await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onSelectNotification: onSelectNotification);

    //! initializing Back4App service
    await Future.delayed(Duration(seconds: 1));
    await _b4a.initParse();
    // ! initialize connection status watch dog
    connectionStatus.initialize();
    //! check for user status on Back4App
    var result = await _b4a.isLogged();
    if (result != null) {
      print('---------------------$result');
      //* initialize RegisterFormFields since user is active in b4a
      registerFormFields.setField(result);
      // if (!_b4a.isEda) {
      //* read from server all messages addressed for this user
      await _initMessageHandler();
      //* built list of contacts
      await _b4a.getAddressees(_addressees);
      //* subscrive for receiving of new messages
      await _b4a.initiateLiveQuery(
          registerFormFields.name, _msg, _regFormEventCtrl.sink,
          mark: "4");
      // }
      _inState.add(AppState.authenticated);
    } else {
      if (_b4a.isEda)
        _inState.add(AppState.unknownEDA);
      //* otherwise go for full blown athentication
      else
        _inState.add(AppState.unauthenticated);
    }
    return;
  }

  Future _initMessageHandler() async {
    print('InitMessageHandler()');
    await _b4a.readMessages(_msg,
        registerFormFields.name); // read all Messages from server for selfuser
    print('Message read completed');
    return null;
  }

  Future onSelectNotification(String payload) async {
    Future.delayed(Duration(seconds: 5));
    print('onSelect Notification invoked');
    // showDialog(
    //     context: context,
    //     builder: (_) => AlertDialog(
    //         title: const Text('New message received'),
    //         content: Text('payload')));
  }

  Future _showNotification(title, body) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, title, body, platformChannelSpecifics, payload: 'item x');
  }

  void connectionChanged(dynamic hasConnection) async {
    isOffline = !hasConnection;
    if (!isOffline) {
      print('*****connection restored******');
      print(uiState);
      // reset app for proper initialization of LiveQuery with delay
      await Future.delayed(Duration(seconds: 3));
      _liveQuery ??= await _b4a.initiateLiveQuery(
          registerFormFields.name, _msg, _regFormEventCtrl.sink,
          mark: '5');
      // _inState.add(AppState.reset);
      // initData();
    } else {
      print('@@@@@@@@@ Inetrnet lost @@@@@@@@@');
      // _liveQuery = null;
      print(uiState);
      // _errorHandler.revertEvent = null;
      // _errorHandler.message = "Network connection lost, service not availible!";
      // _inState.add(AppState.error);
    }
  }

  checkOnNetworkTimeout() {
    if (uiState == UIState.loading) {
      _errorHandler.revertEvent = SwitchToSigninEvent();
      _errorHandler.message = 
          "Network connection to slow or lost, please try again later.";
      _inState.add(AppState.error);
      uiState = UIState.zero;
    }
  }

  void dispose() {
    super.dispose();
    print("*********** Dispose in RegisterBloc ***************");
    _appStateCtrl.close();
    _regFormStateCtrl.close();
    _regFormEventCtrl.close();
    _initFormStateCtrl.close();
    connectionStatus.dispose();
  }
}
