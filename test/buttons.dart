import 'package:flutter/material.dart';

class Buttoons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      //! Button with rounded corners
      child: OutlineButton(
          onPressed: () {},
          child: Text('Aleks'),
          shape: new RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(30.0))),
    );
  }
}
// ! Container with constraints and clip
Widget showroom() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 50),
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 370, maxHeight: 600),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(5.0), child: child)),
  );
}

class HomePageViewModel {
  final bool isLoading;
  final String sessionToken;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomePageViewModel &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          sessionToken == other.sessionToken;

  @override
  int get hashCode => isLoading.hashCode ^ sessionToken.hashCode;

  HomePageViewModel({this.isLoading, this.sessionToken});
}