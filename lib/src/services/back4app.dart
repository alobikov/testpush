import 'dart:async';
import 'dart:convert';
import 'package:device_id/device_id.dart';
import 'package:notify/src/blocs/register/register_bloc.dart';
import 'package:notify/src/models/addressees.dart';
import 'package:notify/src/models/message.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:device_info/device_info.dart';

class ParseService {
  LiveQuery liveQuery;
  bool isEda = false;
  String deviceId;

  static final ParseService _instance = ParseService._internal();
  factory ParseService() => _instance;
  ParseService._internal();

  static const String PARSE_APP_ID = 'iCYTGvNAatQe64smIVqoOidyKKoPx4N0qq3zdH2o';
  static const String PARSE_APP_URL = 'https://parseapi.back4app.com';
  static const String MASTER_KEY = 'lTkaAkYe0jKDFfFEpdWZmgs8jqQwBqwlQyDjKPBS';
  static const String LIVE_QUERY_URL = 'wss://notifyme.back4app.io';
  static const String CLIENT_KEY = '7nsbXEBwo8vRCpdr5Xua2SdnQ1k41M3tg8VHX0SR';
  static const String REST_API_KEY = 'xQXI9GRGAOEi8t8392dm64YMw8U5SFjKaILcG7FU';

  Future<String> initParse() async {
    print('Back4app: Attempting to initialize back4app');

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    this.deviceId = await DeviceId.getID;
    print('Running on ${androidInfo.model}');
    if (androidInfo.model == 'EDA60K') this.isEda = true;
    // print(androidInfo.id); //NMF26F
    // print(androidInfo.device); //eda60k
    //print(androidInfo.androidId); //6dab55fe7311494:

    if (this.isEda) {
      //* initialization for Honeywell
      await Parse().initialize(
        PARSE_APP_ID,
        PARSE_APP_URL,
        masterKey: MASTER_KEY,
        clientKey: CLIENT_KEY,
        liveQueryUrl: LIVE_QUERY_URL,
        autoSendSessionId: true,
        debug: false,
        coreStore: await CoreStoreSharedPrefsImp.getInstance(),
      );
      print("B4A service initialized with MasterKey");
    } else {
      //* initialization for none Honeywell device
      await Parse().initialize(
        PARSE_APP_ID,
        PARSE_APP_URL,
        clientKey: CLIENT_KEY,
        liveQueryUrl: LIVE_QUERY_URL,
        autoSendSessionId: true,
        debug: false,
        coreStore: await CoreStoreSharedPrefsImp.getInstance(),
      );
    }
    var response = await Parse().healthCheck();
    if (response.success) {
      print('Back4app server is OK');
      liveQuery = LiveQuery(debug: false);
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
    await liveQuery?.subscribe(query);
    liveQuery?.on(LiveQueryEvent.create, (value) {
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

  Future<String> createEdaUser(username, form) async {
    form.setField({'name': username});
    form.setField({'deviceId': this.deviceId});
    form.setField({'objectId': 'EDA60K'});
    print(username);
    print(form);
    return await _createSelfUser(form);
  }

  ///! login user with complex logic
  ///! returns null if success or error message string
  Future<String> loginWith(RegisterFormFields form) async {
    var user =
        ParseUser(form.email, form.password, form.name); // create user object
    ParseResponse response = await user.login();
    if (response.success) {
      user = response.result;
      form.setField({'objectId': user.objectId, 'name': user.username});
      print('objectId: ${user.objectId} ${user.username}');
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
      //! deviceId not found in Users table then check for this user using another device
      var queryResult = await queryUsersColumnEqualTo('username', form.name);
      if (queryResult != null) {
        //! found user on another device 'Swapping Device'
        //! delete the record
        print("***************found user on another device 'Swapping Device'");
        await deleteByObjectID('Users', queryResult[0]['objectId']);
      }
      //! and create new Users table record
      print('********Creating new record in Users ***********');
      form.setField({'objectId': user.objectId});
      print('objectId: ${user.objectId}');
      await _createSelfUser(form);

      return null;
    } else {
      //! login failed with message

      return response.error.message;
    }
  }

  /// returns null if success or error message
  Future<String> logout() async {
    // first, unsubcribe for LiveQuery on Messages
    unSubscribe(); 
    if (this.isEda) {
      return await deleteUserByDeviceId(this.deviceId);
    } else {
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
  }

  /// Checks state of current user in Back4App
  Future<Map> isLogged() async {
    if (isEda) {
      //* If user device is EDA then we using Master Key! means EDA is always logged  in :)
      //* just double check that user record exists in Users collection
      //* if not the null will be returned and ancestor will request name from user
      //* and fireup user record creation
      final result = await queryUsersColumnEqualTo('deviceId', this.deviceId);
      print('   query result for user ${this.deviceId}: $result');
      if (result == null) return null;
      if (result.length > 1)
        throw ('more then one record for given user in Users collection');
      final mapa = {
        'name': result[0]['username'],
        'email': 'eda60@honeywell.com',
        'objectId': result[0]['objectId'],
        'deviceId': this.deviceId,
      };
      return mapa;
    } else {
      var user = await ParseUser.currentUser();
      if (user == null)
        return null;
      else {
        final mapa = {
          'name': user['username'],
          'email': user['email'],
          'objectId': user['objectId'],
          'deviceId': this.deviceId,
        };
        return mapa;
      }
    }
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
  /// objectId updates form.objectId
  /// return null if success otherwise error message
  Future<String> _createSelfUser(form) async {
    String deviceid = await DeviceId.getID;
    form.deviceId = deviceid;
    var usersNewObject = ParseObject('Users')
      ..set<String>('deviceId', form.deviceId)
      ..set<String>('userObjId', form.objectId)
      ..set<String>('username', form.name);
    var response = await usersNewObject.create();
    if (response.success && response.result != null) {
      form.setField({'objectId': response.result['objectId']});
      return null;
    } else
      return response.error.message;
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
    final collection = ParseObject(table);
    final result = await collection.delete(id: id);
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

  /// returns null or list of records for 'column' which 'match'es the query
  Future queryUsersColumnEqualTo(String column, String match) async {
    var queryBuilder = QueryBuilder<ParseObject>(ParseObject('Users'))
      ..whereEqualTo(column, match);
    var response = await queryBuilder.query();
    if (response.success && response.result != null) {
      return response.result;
    }
    return null;
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

  /// returns null on success otherwise error message
  Future deleteUserByDeviceId(String deviceId) async {
    var queryBuilder = QueryBuilder<ParseObject>(ParseObject('Users'))
      ..whereEqualTo('deviceId', deviceId);
    var response = await queryBuilder.query();
    print('deleteUserByDeviceId(): ${response.result}');
    if (response.success && response.result != null) {
      response.result.forEach((data) async {
        await deleteByObjectID('Users', data['objectId']);
      });
    } else {
      return response.error.message;
    }
  }

  Future unSubscribe() async {
    final LiveQuery liveQuery = LiveQuery(debug: true);
    await liveQuery.unSubscribe();
  }

}
