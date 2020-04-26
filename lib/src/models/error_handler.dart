import 'package:notify/src/blocs/register/register_bloc.dart';

class ErrorHandler {
  String message;
  RegisterEvent revert;

  ErrorHandler._privateConstructor();

  static final ErrorHandler _instance = ErrorHandler._privateConstructor();

  static ErrorHandler get instance => _instance;
}
