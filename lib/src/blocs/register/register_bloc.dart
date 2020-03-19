import 'dart:async';
import 'package:device_id/device_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notify/src/models/addressees.dart';
import 'package:notify/src/models/error_handler.dart';
import 'package:notify/src/models/message.dart';
import 'package:notify/src/services/back4app.dart';
import 'package:notify/utils/connection_status.dart';
// import 'package:notify/src/services/create_object.dart';

part 'register_event.dart';
part 'register_state.dart';

enum AppState {
  uninitialized,
  authenticated,
  unauthenticated,
  unregistred,
  sendMessageForm,
  loading,
  error,
  reset,
}
enum UIState { home, messageSendForm, loading, signin, zero, alertScreen }

class RegisterBloc extends ChangeNotifier {
  final _msg = Messages.instance;
  // final _msgToSend = MessageToSend();
  final _b4a = ParseService();
  final _addressees = Addressees();
  final _errorHandler = ErrorHandler.instance;
  final _registerFormFields;
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

  RegisterInitFields initFields;

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
  RegisterFormFields get getFormFields => _registerFormFields;

  // ! Register Bloc constructor
  RegisterBloc() : _registerFormFields = RegisterFormFields() {
    print('!!!!!!!  Register block constructor invoked !!!!!!!!!');

    _regFormEventCtrl.stream.listen(_mapEventController);

    /// this stream is used to inform about internet connectivity changes
    _connectionChangeStream =
        connectionStatus.connectionChange.listen(connectionChanged);

    /// this stream used to receive data from TextFormFields
    formState.listen((form) {
      print('formState in Bloc received: $form');
      _registerFormFields.setField(form);
      // print('Current state of RegFormFields ${_registerFormFields.show()}');
    });
  }

  void _mapEventController(event) async {
    //***************************************/
    //* Populate Register/Signin form by mock user date
    if (event is PopulateFormEvent) {
      print('Populate button event');
      _registerFormFields.setField(RegisterInitFields.getAll);
      RegisterInitFields.advanceToNextUser();
      print('RegisterFormFields: ${_registerFormFields.show()}');
      notifyListeners();
      return;
      //
      //***************************************/
      //* Register User event handler
    } else if (event is SubmitFormEvent) {
      _inState.add(AppState.loading);
      // print('Submitted Register Form ${_registerFormFields.show()}');
      //* create account at BACK4APP if failed display error in AlertDialog
      await _b4a.logout(); //! but first make sure user not logged in
      _msg.clear(); // clear local message repository
      var error = await _b4a.registerWith(_registerFormFields);
      if (error != null) {
        // Alert() is common usage UI and it needs additional information
        // The revert point is one of this
        // We using ErrorHandler singleton to pass extra information
        _errorHandler.revert = SwitchToRegisterEvent();
        _errorHandler.message = error;
        _inState.add(AppState.error);
      } else {
        // read all messages from server to local repository
        await _initMessageHandler();
        // subscribe to LiveQuery on 'Messages'
        _liveQuery = await _b4a.initiateLiveQuery(
            _registerFormFields.name, _msg, _regFormEventCtrl.sink);
        _inState.add(AppState.authenticated); // show Home()
      }
      return;
      //
      //***************************************/
      //* SignIn event handler - Signin button pressed
    } else if (event is SigninFormEvent) {
      print('**********SignInFormEvent ');
      _inState.add(AppState.loading);
      _msg.clear(); // clear local message repository
      var error = await _b4a.loginWith(_registerFormFields);
      if (error != null) {
        print("Login failed");
        // Alert() is common usage UI and it needs additional information
        // The revert point is one of this
        // We using ErrorHandler singleton to pass extra information
        _errorHandler.revert = SwitchToSigninEvent();
        _errorHandler.message = error;
        _inState.add(AppState.error);
      } else {
        // read all messages from server to local repository
        await _initMessageHandler();
        // subscribe to LiveQuery on 'Messages'
        _liveQuery = await _b4a.initiateLiveQuery(
            _registerFormFields.name, _msg, _regFormEventCtrl.sink);
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
      await _b4a.logout();
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
      _inState.add(AppState.authenticated);
    }
    return;
  }

  String getFormFieldFor(String field) {
    return _registerFormFields.getField(field);
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
    await Future.delayed(Duration(seconds: 2));
    await _b4a.initParse();
    // ! initialize connection status watch dog
    connectionStatus.initialize();
    //! check for user status on Back4App
    if (await _b4a.isLogged()) {
      //* init RegisterFormFields since user is active in b4a
      var user = await _b4a.getCurrentUser();
      _registerFormFields.setField({
        'name': user['username'],
        'email': user['email'],
        'objectId': user['objectId'],
        'deviceId': await DeviceId.getID,
      });
      //!
      await _initMessageHandler();
      await _b4a.getAddressees(
          _addressees); // read from server and prepare for use Addressees list
      await _b4a.initiateLiveQuery(
          _registerFormFields.name, _msg, _regFormEventCtrl.sink);
      _inState.add(AppState.authenticated);
    } else {
      _inState.add(AppState.unauthenticated);
    }
    return;
  }

  Future _initMessageHandler() async {
    print('InitMessageHandler()');
    await _b4a.readMessages(_msg,
        _registerFormFields.name); // read all Messages from server for selfuser
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
      // reset app for proper initializationof LiveQuery with delay
      await Future.delayed(Duration(seconds: 7));
      _inState.add(AppState.reset);
    } else {
      print('@@@@@@@@@ Inetrnet lost @@@@@@@@@');
      print(uiState);
    }
  }

  checkOnNetworkTimeout() {
    if (uiState == UIState.loading) {
      _errorHandler.revert = SwitchToSigninEvent();
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
