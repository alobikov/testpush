import 'package:flutter/material.dart';
import 'package:notify/src/blocs/register/register_bloc.dart';
import 'package:notify/src/blocs/send_message/send_bloc.dart';
import 'package:notify/src/ui/widgets/alert.dart';
import 'package:notify/utils/connection_status.dart';
import 'package:provider/provider.dart';

class SendForm extends StatefulWidget {
  @override
  _SendFormState createState() => _SendFormState();
}

class _SendFormState extends State<SendForm> {
  final _bloc = SendMessageBloc();
  String _menuValue, _text;
  ConnectionStatusSingleton connectionStatus =
      ConnectionStatusSingleton.getInstance();

  @override
  dispose() {
    super.dispose();
    _bloc.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user =
        Provider.of<RegisterBloc>(context, listen: false).getFormFields;
    return Scaffold(
      backgroundColor: Colors.teal[100],
      appBar: AppBar(
        title: Text('Send Notification Message'),
        actions: <Widget>[],
      ),
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text("Send to:", style: TextStyle(fontSize: 16)),
                  SizedBox(
                    width: 20.0,
                  ),
                  StreamBuilder<List<String>>(
                      stream: _bloc.menuList,
                      initialData: List<String>(),
                      builder: (context, AsyncSnapshot<List<String>> snapshot) {
                        return DropdownButton<String>(
                          value: _menuValue,
                          hint: Text('Select'),
                          items: snapshot.data.map((val) {
                            return DropdownMenuItem<String>(
                                child: Text(val), value: val);
                          }).toList(),
                          onChanged: (data) {
                            setState(() {
                              _menuValue = data;
                            });
                          },
                        );
                      }),
                  Spacer(),
                ],
              ),
              // Text('Message:', style: TextStyle(fontSize: 16)),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                color: Colors.white,
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _text = val;
                    });
                  },
                  maxLines: 2,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10.0),
                    border: InputBorder.none,
                  ),
                ),
              ),
              SizedBox(height: 6),
              RaisedButton(
                child: Text('Send Message'),
                onPressed: _text != null && _menuValue != null
                    ? () {
                        if (connectionStatus.hasConnection) {
                          _bloc.inForm.add(SendMsgAction(
                            action: FormAction.submit,
                            body: _text,
                            to: _menuValue,
                            from: user.name,
                          ));
                          Navigator.pop(context);
                        } else
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Alert(
                                message:
                                    "Internet connection lost! Service not availible!",
                                revert: null,
                              ),
                            ),
                          );
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
