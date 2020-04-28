import 'package:flutter/material.dart';
import 'package:notify/src/blocs/register/register_bloc.dart';
import 'package:provider/provider.dart';

class Alert extends StatelessWidget {
  final String message;
  final revert;
  const Alert({Key key, @required this.message, @required this.revert})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: AlertDialog(
          title: Text('Alert message:'),
          content: Text(message),
          actions: <Widget>[
            FlatButton(
              child: Text('Dismiss'),
              onPressed: () {
                if (revert != null)
                  Provider.of<RegisterBloc>(context, listen: false)
                      .event
                      .add(revert);
                else
                  Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
