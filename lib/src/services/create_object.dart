import 'package:notify/src/models/message.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

final _msg = NotyMessage(
    body: 'mersdfasdf', to: 'Petras', from: 'Aleks', title: 'title');

/// Saves ParseObject in parse database
///
/// returns null if success otherwise <String> error message
Future<String> createObject() async {
  var message = ParseObject('Messages')
    ..set('body', _msg.body)
    ..set('to', _msg.to)
    ..set('from', _msg.from) //! aka currentUser
    ..set('timestamp', DateTime.now().toString().substring(0, 16))
    ..set('title', _msg.title);
  // print('createObject body ${_msg.body}');
  var response = await message.save();
  if (!response.success) return response.error.message;
  return null;
}
