import 'package:flutter/material.dart';
import 'package:notify/src/blocs/register/register_bloc.dart';
import 'package:notify/src/services/back4app.dart';
import 'package:provider/provider.dart';

class IntroduceYourself extends StatefulWidget {
  IntroduceYourself({Key key}) : super(key: key);

  @override
  _IntroduceYourselfState createState() => _IntroduceYourselfState();
}

class _IntroduceYourselfState extends State<IntroduceYourself> {
  final _b4a = ParseService();
  final _textController = TextEditingController();
  bool isButtonValid = false;
  bool isLoading = false;
  String errorMsg = '';

  void handleText() {
    final length = _textController.text.length;

    if (length > 0 && length < 3)
      setState(() => isButtonValid = false);
    else if (length == 0)
      setState(() => isButtonValid = false);
    else
      setState(() => isButtonValid = true);
  }

  void nameSubmitted() async {
    final username = _textController.text.trim();
    setState(() => isLoading = true);
    final form =
        Provider.of<RegisterBloc>(context, listen: false).registerFormFields;
    final response = await _b4a.createEdaUser(username, form);
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      isLoading = false;
      if (response != null) errorMsg = response;
    });
    if (response == null)
      Provider.of<RegisterBloc>(context, listen: false)
          .event
          .add(NavigateToHomeEvent());
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    _textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _textController.addListener(handleText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.fromLTRB(50, 50, 50, 10),
        child: Column(
          children: <Widget>[
            Text('Welcome to Notify', style: TextStyle(fontSize: 24)),
            SizedBox(height: 15),
            Text('Enter your username', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Your name',
              ),
            ),
            SizedBox(height: 10),
            errorMsg != '' ? error() : isLoading ? progress() : fillbox(),
            ButtonTheme(
              minWidth: double.infinity,
              height: 50.0,
              child: RaisedButton(
                child: Text('Submit'),
                onPressed: isButtonValid ? nameSubmitted : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget progress() {
    return Column(
      children: <Widget>[
        SizedBox(height: 5),
        LinearProgressIndicator(),
        SizedBox(height: 15),
      ],
    );
  }

  Widget error() {
    return Column(
      children: <Widget>[
        SizedBox(height: 0),
        Text(
          errorMsg,
          style: TextStyle(color: Colors.red),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget fillbox() {
    return SizedBox(height: 24);
  }
}
