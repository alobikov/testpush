part of 'register_bloc.dart';

abstract class RegisterState {
  get name => null;
  get password => null;
  get email => null;
  get confirmPassword => null;
}

class RegisterInitFields {
  static List<Map<String, String>> _form = [
    {
      'name': "Aleks",
      'email': "aleksej.lobikov@gmail.com",
      'password': "qwerty",
      'confirmPassword': "qwerty",
    },
    {
      'name': "Mario",
      'email': "mario@yahoo.com",
      'password': "asdfgh",
      'confirmPassword': "asdfgh",
    },
    {
      'name': "Petras",
      'email': "petras@mail.ru",
      'password': "p12345",
      'confirmPassword': "p12345",
    },
    {
      'name': "",
      'email': "",
      'password': "",
      'confirmPassword': "",
    },
  ];

  static int _currentMockUserId = 0;

  static get getAll => _form[_currentMockUserId];

  static void advanceToNextUser() {
    _currentMockUserId = ++_currentMockUserId % _form.length;
  }
}

class RegisterFormFields extends RegisterState {
  Map<String, dynamic> form = Map();

  String get name => form['name'];
  String get email => form['email'];
  String get password => form['password'];
  String get objectId => form['objectId'];
  String get deviceId => form['deviceId'];

  set deviceId(str) => form['deviceId'] = str;

  void setField(Map<String, dynamic> field) => form.addAll(field);

  String getField(String field) => form[field];

  void show() => form;
}
