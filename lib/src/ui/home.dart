import 'package:flutter/material.dart';
import 'package:notify/src/blocs/send_message/send_message_form.dart';
import 'package:notify/src/ui/drawer.dart';
import 'package:notify/src/ui/msg_list.dart';
import 'package:notify/src/ui/widgets/alert.dart';
import 'package:notify/utils/connection_status.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ConnectionStatusSingleton connectionStatus =
        ConnectionStatusSingleton.getInstance();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Notify'),
        actions: <Widget>[
          FlatButton.icon(
            label: Text('Send Message',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            onPressed: () {
              if (connectionStatus.hasConnection)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SendForm(),
                  ),
                );
              else
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
            },
            //! replaced by simple Navigator.push
            //  () => Provider.of<RegisterBloc>(context, listen: false)
            //     .event
            //     .add(SendMessageFormEvent()),
            icon: Icon(Icons.message, color: Colors.black),
          )
        ],
      ),
      drawer: AppDrawer(),
      body: MsgList(),
    );
  }
}
