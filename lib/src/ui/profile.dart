import 'package:flutter/material.dart';
import 'package:notify/src/blocs/register/register_bloc.dart';
import 'package:provider/provider.dart';

class Profile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user =
        Provider.of<RegisterBloc>(context, listen: false).getFormFields;
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Container(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Current user information', style: TextStyle(fontSize: 18)),
              SizedBox(height: 10.0),
              Text('User name: ${user.name}'),
              Text('User email: ${user.email}'),
              Text('Back4App objectID: ${user.objectId}'),
              Text('Device ID: ${user.deviceId}'),
            ],
          )),
    );
  }
}
