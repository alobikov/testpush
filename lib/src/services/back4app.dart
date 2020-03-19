import 'dart:async';
import 'dart:convert';
import 'package:device_id/device_id.dart';
import 'package:notify/src/blocs/register/register_bloc.dart';
import 'package:notify/src/models/addressees.dart';
import 'package:notify/src/models/message.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

class ParseService {
  LiveQuery liveQuery;

  static final ParseService _instance = ParseService._internal();
  factory ParseService() => _instance;
  ParseService._internal();

  static const String PARSE_APP_ID = 'iCYTGvNAatQe64smIVqoOidyKKoPx4N0qq3zdH2o';
  static const String PARSE_APP_URL = 'https://parseapi.back4app.com';
  static const String MASTER_KEY = 'lTkaAkYe0jKDFfFEpdWZmgs8jqQwBqwlQyDjKPBS';
  static const String LIVE_QUERY_URL = 'wss://notifyme.back4app.io';
  static const String CLIENT_KEY = '7nsbXEBwo8vRCpdr5Xua2SdnQ1k41M3tg8VHX0SR';

  Future<String> initParse() async {
    print('Back4app: Attempting to initialize back4app');
    await Parse().initialize(
      PARSE_APP_ID, PARSE_APP_URL,
      // masterKey: MASTER_KEY,
      clientKey: CLIENT_KEY,
      liveQueryUrl: LIVE_QUERY_URL,
      autoSendSessionId: true,
      debug: false,
      coreStore: await CoreStoreSharedPrefsImp.getInstance(),
    );

    var response = await Parse().healthCheck();
    if (response.success) {
      print('Back4app server is OK');
      liveQuery = LiveQuery(debug: true);
      // createItem();
      // getAllItemsByName();
    } else {
      print("Server health check failed");
    }
    return 'initParse() is complete';
  }

  Future initiateLiveQuery(
      String selfuser, Messages _msg, StreamSink sink) async {
    await ParseUser.currentUser();
    QueryBuilder<ParseObject> query =
        QueryBuilder<ParseObject>(ParseObject('Messages'))
          ..whereEqualTo('to', selfuser);
    // create subscription
//    await liveQuery.unSubscribe();
    await liveQuery.subscribe(query);
    liveQuery.on(LiveQueryEvent.create, (value) {
      print(
          '*** LIVE QUERY RECEIVED ***: ${DateTime.now().toString()}\n $value ');
      NotyMessage msg = NotyMessage(
          body: (value as ParseObject).get('body'),
          from: (value as ParseObject).get('from'),
          objectId: (value as ParseObject).get('objectId'),
          timestamp: (value as ParseObject).get('timestamp') ?? '2020-03-12');
      _msg.messages.insert(0, msg); //* add new message into the top of the list
      sink.add(NewMessage(
          msg)); //* Notify RegisterBlock about new message and pass the message instance
    });
//    await liveQuery.unSubscribe();
    print('LiveQuery in mwthod ${liveQuery.hashCode}');
    return liveQuery;
  }

  // Future unSubscribe() async {
  //   final LiveQuery liveQuery = LiveQuery(debug: true);
  //   await liveQuery.unSubscribe();
  // }

  /// returns null if success or error message
  Future<String> registerWith(RegisterFormFields form) async {
    var user = ParseUser(
        form.name, form.password, form.email); // first, create user object
    ParseResponse response = await user.signUp();
    if (response.success) {
      // after successful registration create record in 'Users' table
      // but before that
      // check if the record for this deviceId already there
      // return null or username
      var apiResponse =
          await queryUsersColumnEqualTo('deviceId', await DeviceId.getID);
      // if deviceId was in use then delete all messages addressed to him
      if (apiResponse != null) {
        String username = apiResponse[0]['username'];
        String objectId = apiResponse[0]['objectId'];
        print('Heh device in use, lets clean db, for $username $objectId');
        await deleteAllMessages(username);
        // and finally remove record in 'Users'
        await deleteByObjectID('Users', objectId);
      }
      user = response.result;
      form.setField({'objectId': user.objectId});
      print('objectId: ${user.objectId}');
      await _createSelfUser(form);
      return null;
    } else {
      return response.error.message;
    }
  }

  ///! login user with complex logic
  ///! returns null if success or error message string
  Future<String> loginWith(RegisterFormFields form) async {
    var user =
        ParseUser(form.email, form.password, form.name); // create user object
    ParseResponse response = await user.login();
    if (response.success) {
      user = response.result;
      form.setField({'objectId': user.objectId});
      print('objectId: ${user.objectId}');
      //! user logged in! now check Users table for this deviceId
      //! if found check for deviceId and this username match
      var apiResponse =
          await queryUsersColumnEqualTo('deviceId', await DeviceId.getID);
      // result null if not found otherwise
      // [{"className":"Users","objectId":"Tcjy4x9RnK","createdAt":"2020-03-17T17:53:34.011Z","updatedAt":"2020-03-17T17:53:34.011Z","deviceId":"6f0d2751d08a5bfe","userObjId":"EXrmKyGUkH","username":"Petras"}]
      if (apiResponse != null) {
        //! diviceId found in table then check for match of
        //! table username and this username
        if (apiResponse[0]['username'] != form.name) {
          //! usernames don't match -> delete record
          print('********usernames dont match -> delete record');
          await deleteByObjectID('Users', apiResponse[0]['objectId']);
          //! create new record
          print('********Creating new record in Users ***********');
          form.setField({'objectId': user.objectId});
          print('objectId: ${user.objectId}');
          await _createSelfUser(form);
        }
        //! Users record belong to this user on this device - do nothing more
        return null;
      }
      //! deviceId not found in Users table then check for user using another device
      var queryResult = await queryUsersColumnEqualTo('username', form.name);
      if (queryResult != null) {
        //! found user on another device 'Swapping Device'
        //! delete the record
        print("***************found user on another device 'Swapping Device'");
        await deleteByObjectID('Users', queryResult[0]['objectId']);
        //! and create new Users table record
        print('********Creating new record in Users ***********');
        form.setField({'objectId': user.objectId});
        print('objectId: ${user.objectId}');
        await _createSelfUser(form);
      }
      return null;
    } else {
      //! login failed with message
      return response.error.message;
    }
  }

  /// returns null if success or error message
  Future<String> logout() async {
    var user = await ParseUser.currentUser();
    print('Logout user $user');
    if (user != null) {
      // only if user logged in then logout
      var response = await user.logout();
      if (response.success)
        print('User logout success');
      else
        print('User logout failed');
    }
    return null;
  }

  /// Checks state of current user in Back4App
  Future<bool> isLogged() async {
    var user = await ParseUser.currentUser();
    if (user == null)
      return false;
    else
      // print('isLogged: ${user['username']}');
      return true;
  }

  /// this information retieved from b4a User
  Future getCurrentUser() async {
    var user = await ParseUser.currentUser();
    return user;
  }

  /// Gets List<Map> of users from Back4App
  getAllUsers() async {
    var users = await ParseObject('Users').getAll();
    if (users.success) {
      // for (var user in users.result) {
      // print(user.toString());
      print('getAllUsers users: ${users.result}');
      // }
    }
    return null;
  }

  /// creates record of this.user in Users on b4a
  _createSelfUser(form) async {
    String deviceid = await DeviceId.getID;
    form.deviceId = deviceid;
    var usersNewObject = ParseObject('Users')
      ..set<String>('deviceId', form.deviceId)
      ..set<String>('userObjId', form.objectId)
      ..set<String>('username', form.name);
    var response = await usersNewObject.create();
    if (response.success && response.result != null)
      print('User recorded in "Users" collection');
    else
      print('Users collection upfdate failed');
    return null;
  }

  Future createMessage({String to, String body, String from}) async {
    var newObject = ParseObject('Messages')
      ..set<String>('to', to.trim())
      ..set<String>('from', from.trim())
      ..set<String>('body', body.trim())
      ..set<String>('timestamp', DateTime.now().toString().substring(0, 16));

    var apiResponse = await newObject.create();

    if (apiResponse.success && apiResponse.result != null) {
      print("createMessage(): " + apiResponse.result.toString());
    }
    return null;
  }

  Future deleteByObjectID(String table, String id) async {
    var collection = ParseObject(table);
    var result = await collection.delete(id: id);
    print('Deleting object result ${result.result}');
    return result.result;
  }

  void getAllItemsByName() async {
    var apiResponse = await ParseObject('Pet').getAll();

    if (apiResponse.success && apiResponse.result != null) {
      for (var testObject in apiResponse.result) {
        print("pushapp: " + testObject.toString());
      }
    }
  }

  getAddressees(Addressees obj) async {
    var apiResponse = await ParseObject('Users').getAll();
    var resultMap = Map<String, String>();
    if (apiResponse.success && apiResponse.result != null) {
      for (var user in apiResponse.result) {
        obj.list.add(jsonDecode(user.toString()));
      }

      for (var user in obj.list) {
        resultMap
            .addAll({user['username'].toString(): user['objectId'].toString()});
      }
    }
    obj.users.clear();
    obj.users.addAll(resultMap);
    print(obj.users);
  }

  Future<List<String>> getAdresats() async {
    var apiResponse = await ParseObject('Users').getAll();
    var result = List<String>();
    if (apiResponse.success && apiResponse.result != null) {
      for (var user in apiResponse.result) {
        result.add(jsonDecode(user.toString())['username']);
      }
      print(result);
      return result;
    }
    return null; // retrieve failed
  }

  Future readMessages(Messages _msg, String selfuser) async {
    var queryBuilder = QueryBuilder<ParseObject>(ParseObject('Messages'))
      ..whereEqualTo('to', selfuser);

    var response = await queryBuilder.query();
    if (response.success && response.result != null) {
      _msg.messages.clear(); // delete all localy stored messages
      for (var message in response.result) {
        _msg.messages.insert(
            0,
            NotyMessage(
                body: message['body'],
                from: message['from'],
                objectId: message['objectId'],
                timestamp: message['timestamp'] ?? '2020-03-12'));
        // print(message);
      }
    }
    return null;
  }

  /// returns null or records in column which match query
  Future queryUsersColumnEqualTo(String column, String match) async {
    var queryBuilder = QueryBuilder<ParseObject>(ParseObject('Users'))
      ..whereEqualTo(column, match);
    var response = await queryBuilder.query();
    if (response.success && response.result != null) {
      return response.result;
    }
    return null;
  }

  Future deleteAllMessages(String username) async {
    var queryBuilder = QueryBuilder<ParseObject>(ParseObject('Messages'))
      ..whereEqualTo('to', username);
    var response = await queryBuilder.query();
    if (response.success && response.result != null) {
      response.result.forEach((id) async {
        await deleteByObjectID('Messages', id['objectId']);
      });
    }
  }

  /// returns null or username registered with this deviceId
  Future deleteUserByName(String username) async {
    var queryBuilder = QueryBuilder<ParseObject>(ParseObject('Users'))
      ..whereEqualTo('username ', username);
    var response = await queryBuilder.query();
    if (response.success && response.result != null) {
      return response.result.first();
    }
    return null;
  }
}
