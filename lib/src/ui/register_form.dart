import 'package:flutter/material.dart';
import 'package:notify/shared/dialogs.dart';
import 'package:notify/src/blocs/register/register_bloc.dart';
import 'package:provider/provider.dart';

class RegisterForm extends StatefulWidget {
  RegisterForm() {
    print('RegisterForm constructor envoked');
  }

  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  String _nameError;

  @override
  Widget build(BuildContext context) {
    final _blocP = Provider.of<RegisterBloc>(context, listen: false);
    return StreamBuilder(
      stream: _blocP.initiateState,
      initialData: null,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          print('register form stream builder got data');
          WidgetsBinding.instance.addPostFrameCallback((_) =>
              showDialogFunction(
                  context, 'Registration failed', snapshot.data));
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
                  child: Text('Create Account', style: TextStyle(fontSize: 28)),
                ),
                SizedBox(height: 20),
                Consumer<RegisterBloc>(
                  builder: (context, bloc, child) {
                    return TextFormField(
                      controller: TextEditingController(
                        text: bloc.getFormFieldFor('name'), //! not usimg stream
                      ),
                      autofocus: false,
                      maxLength: 20,
                      onChanged: (field) {
                        bloc.inForm.add({'name': field}); //! textfiled sink
                      },
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Name",
                          labelText: "Account name",
                          errorText: _nameError),
                    );
                  },
                ),
                SizedBox(
                  height: 10.0,
                ),
                Consumer<RegisterBloc>(
                  builder: (context, bloc, child) {
                    print('email field updated');
                    return TextFormField(
                      controller: TextEditingController(
                        text:
                            bloc.getFormFieldFor('email'), //! not usimg stream
                      ),
                      maxLength: 50,
                      autofocus: false,
                      onChanged: (field) {
                        bloc.inForm.add({'email': field}); //! textfiled sink
                      },
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Enter email",
                          labelText: "Email",
                          errorText: bloc.emailError),
                    );
                  },
                ),
                SizedBox(
                  height: 10.0,
                ),
                Consumer<RegisterBloc>(
                  builder: (context, bloc, child) {
                    return TextFormField(
                      controller: TextEditingController(
                        text: bloc
                            .getFormFieldFor('password'), //! not usimg stream
                      ),
                      autofocus: false,
                      onChanged: (field) {
                        bloc.inForm.add({'password': field}); //! textfiled sink
                      },
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
                  height: 10.0,
                ),
                Consumer<RegisterBloc>(
                  builder: (context, bloc, child) {
                    return TextFormField(
                      controller: TextEditingController(
                        text: bloc.getFormFieldFor(
                            'confirmPassword'), //! not usimg stream
                      ),
                      autofocus: false,
                      onChanged: (field) {
                        bloc.inForm
                            .add({'confirmPassword': field}); //! textfiled sink
                      },
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Confirm password",
                          labelText: "Confirm",
                          errorText: null),
                    );
                  },
                ),
                SizedBox(
                  height: 20.0,
                ),
                RaisedButton(
                  color: Color(0xFF02BB9F),
                  child: Text('Submit', style: TextStyle(fontSize: 18)),
                  onPressed: () {
                    _formKey.currentState.save();
                    print('Register Form: form saved');
                    Provider.of<RegisterBloc>(context, listen: false)
                        .event
                        .add(SubmitFormEvent());
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
