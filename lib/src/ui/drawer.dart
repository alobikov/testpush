import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notify/main.dart';
import 'package:notify/src/blocs/register/register_bloc.dart';
import 'package:notify/src/ui/profile.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatefulWidget {
  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    final _blocP = Provider.of<RegisterBloc>(context, listen: false);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 120.0,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF02BB9F),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      // IconButton(
                      //   padding: EdgeInsets.all(0.0),
                      //   onPressed: () {
                      //     Navigator.pop(context);
                      //   },
                      //   icon: Icon(Icons.arrow_back),
                      // ),
                      Text(
                        'Notify settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Logout'),
            onTap: () async {
              _blocP.event.add(UserLogoutEvent());
              Navigator.pop(context);
              // Navigator.popAndPushNamed(context, '/wrapper');
            },
          ),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Profile'),
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => Profile()));
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('About'),
            onTap: () {
              _about();
            },
          ),
          ListTile(
            leading: Icon(Icons.arrow_back),
            title: Text('Close'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.clear),
            title: Text('Exit Notify'),
            onLongPress: () {
              // RestartWidget.restartApp(context);
              SystemNavigator.pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _about() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('About'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Android Build'),
                Text(CURRENT_RELEASE),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Close',
                  style: TextStyle(color: Colors.brown[600], fontSize: 18.0)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
