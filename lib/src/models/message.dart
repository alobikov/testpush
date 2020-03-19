class NotyMessage {
  String from;
  String to;
  String title;
  String body;
  String timestamp;
  String objectId;

  NotyMessage(
      {this.from,
      this.to,
      this.title,
      this.body,
      this.timestamp,
      this.objectId});
}

class Messages {
  List<NotyMessage> messages = List();

  Messages._privateConstructor();

  static final Messages _instance = Messages._privateConstructor();

  static Messages get instance => _instance;
  void deleteMessageLocalyId(id) {
    messages.removeWhere((item) => id == item.objectId);
  }

  void clear() {
    messages.clear();
  }

  void buildMockList() {
    for (int i = 0; i < 20; i++) {
      messages.insert(
        0,
        NotyMessage(
            from: 'Mario$i',
            title: 'title$i',
            body: 'Lorem ipsum dribsum tam',
            timestamp: DateTime.now().toString().substring(0, 16)),
      );
    }
  }
}

// class MessageToSend {
//   String to;
//   String body;
//   String from;
//   String timestamp;

//   MessageToSend._privateConstructor();
//   static final MessageToSend _instance = MessageToSend._privateConstructor();
//   factory MessageToSend() {
//     return _instance;
//   }
// }`
