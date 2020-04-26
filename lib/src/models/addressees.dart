class Addressees {
  static final Addressees _instance = Addressees._internal();
  final list = List<Map<String, dynamic>>();
  final users = Map<String, String>();
  factory Addressees() {
    return _instance;
  }
  Addressees._internal();
}
