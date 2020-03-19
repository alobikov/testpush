import 'package:flutter/material.dart';
import 'package:notify/src/blocs/register/register_bloc.dart';
import 'package:notify/src/ui/signin_form.dart';
import 'package:provider/provider.dart';

class Signin extends StatefulWidget {
  @override
  _SigninState createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  @override
  void dispose() {
    // Provider.of<RegisterBloc>(context, listen: false).dispose();
    super.dispose();
  }

  void initState() {
    super.initState();
    print('Signin State initState invoked');
  }

  @override
  Widget build(BuildContext context) {
    print('SigninState widget rebuilt');
    return Scaffold(
      appBar: AppBar(
        title: Text('Notify App'),
        actions: <Widget>[
          FlatButton.icon(
            onPressed: () => Provider.of<RegisterBloc>(context, listen: false)
                .event
                .add(SwitchToRegisterEvent()),
            icon: Icon(Icons.person, color: Colors.black),
            label: Text('Register', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF02BB9F),
        foregroundColor: Colors.black,
        child: Icon(Icons.refresh),
        onPressed: () {
          Provider.of<RegisterBloc>(context, listen: false)
              .event
              .add(PopulateFormEvent());
        },
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.all(16),
          child: Consumer<RegisterBloc>(
            builder: (context, bloc, child) {
              print('Signin Form Consumer activated');
              return SigninForm();
            },
          ),
        ),
      ),
    );
  }
}
