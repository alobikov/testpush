import 'package:flutter/material.dart';
import 'package:notify/src/blocs/register/register_bloc.dart';
import 'package:notify/src/ui/register_form.dart';
import 'package:provider/provider.dart';

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  @override
  void dispose() {
    // Provider.of<RegisterBloc>(context, listen: false).dispose();
    super.dispose();
  }

  void initState() {
    super.initState();
    print('Register State initState invoked');
  }

  @override
  Widget build(BuildContext context) {
    print('RegisterState widget rebuilt');
    return Scaffold(
      appBar: AppBar(
        title: Text('Notify App'),
        actions: <Widget>[
          FlatButton.icon(
            onPressed: () => Provider.of<RegisterBloc>(context, listen: false)
                .event
                .add(SwitchToSigninEvent()),
            icon: Icon(Icons.person, color: Colors.black),
            label: Text('Sign in', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF02BB9F),
        foregroundColor: Colors.black,
        child: Icon(Icons.refresh),
        onPressed: () {
          // Provider.of<RegisterBloc>(context, listen:false).notify();
          Provider.of<RegisterBloc>(context, listen: false)
              .event
              .add(PopulateFormEvent());
        },
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.all(16),

          child:
              //  StreamBuilder(
              //   stream:
              //       Provider.of<RegisterBloc>(context, listen: false).initiateState,
              //   initialData: null,
              //   builder: (BuildContext context, AsyncSnapshot snapshot) {
              //     if (snapshot.data != null) {_never();}

              //     return
              RegisterForm(),
          // },
        ),

        //  Consumer<RegisterBloc>(
        //   builder: (context, bloc, child) {
        //     print('Consumer activated');
        //     return RegisterForm();
        // },
      ),
    );
  }
}
