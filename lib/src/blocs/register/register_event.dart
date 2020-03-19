part of 'register_bloc.dart';

abstract class RegisterEvent {}

class PopulateFormEvent extends RegisterEvent {}

class SubmitFormEvent extends RegisterEvent {}

class SwitchToSigninEvent extends RegisterEvent {}

class SwitchToRegisterEvent extends RegisterEvent {}

class SigninFormEvent extends RegisterEvent {}

class UserLogoutEvent extends RegisterEvent {}

class SendMessageFormEvent extends RegisterEvent {}

class SendMessageSubmitEvent extends RegisterEvent {}

class SendMessageEvent extends RegisterEvent {}

class InitializeApp extends RegisterEvent {}

class NewMessage extends RegisterEvent {
  NewMessage(this._msg);
  final _msg;
  NotyMessage get msg => _msg;
}

class NavigateToHomeEvent extends RegisterEvent {}
