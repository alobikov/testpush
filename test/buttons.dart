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