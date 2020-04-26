import 'package:flutter/material.dart';
import 'package:notify/shared/dialogs.dart';
import 'package:notify/src/blocs/register/register_bloc.dart';
import 'package:provider/provider.dart';

class SigninForm extends StatefulWidget {
  SigninForm() {
    print('RegisterForm constructor envoked');
  }

  @override
  _SigninFormState createState() => _SigninFormState();
}

class _SigninFormState extends State<SigninForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final _blocP = Provider.of<RegisterBloc>(context, listen: false);
    return StreamBuilder(
      stream: _blocP.initiateState,
      initialData: null,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          print('signin form stream builder got data');
          WidgetsBinding.instance.addPostFrameCallback((_) =>
              showDialogFunction(context, 'Login failed', snapshot.data));
          _blocP.initiateForm.add(null); //* load next snapshot with null
        }
        return Container(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 20),
                Center(
                  child: Text('Login to your account',
                      style: TextStyle(fontSize: 28)),
                ),
                SizedBox(height: 20),
                Consumer<RegisterBloc>(
                  builder: (context, bloc, child) {
                    print('Consumer activated');
                    return TextFormField(
                      controller: TextEditingController(
                          text: bloc.getFormFieldFor('email')),
                      maxLength: 50,
                      autofocus: false,
                      onChanged: (field) {
                        bloc.inForm.add({'email': field});
                      }, //! textfiled sink
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Enter email",
                          labelText: "Email",
                          errorText: null),
                    );
                  },
                ),
                SizedBox(
                  height: 20.0,
                ),
                Consumer<RegisterBloc>(
                  builder: (context, bloc, child) {
                    print('Consumer activated');
                    return TextFormField(
                      controller: TextEditingController(
                          text: bloc.getFormFieldFor('password')),
                      autofocus: false,
                      obscureText: true,
                      onChanged: (field) {
                        bloc.inForm.add({'password': field});
                      }, //! textfiled sink
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Enter password",
                          labelText: "Password",
                          errorText: null),
                    );
                  },
                ),
                SizedBox(
                  height: 20.0,
                ),
                RaisedButton(
                  color: Color(0xFF02BB9F),
                  child: Text('Sign in', style: TextStyle(fontSize: 18)),
                  onPressed: () {
                    _formKey.currentState.save();
                    print('Signin Form: form saved');
                    _blocP.event.add(SigninFormEvent());
                  },
                ),
                Expanded(
                  child: Container(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
