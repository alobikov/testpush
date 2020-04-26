import 'package:flutter/material.dart';
import 'package:notify/src/models/message.dart';
import 'package:notify/src/services/back4app.dart';

class MsgList extends StatefulWidget {
  @override
  _MsgListState createState() => _MsgListState();
}

class _MsgListState extends State<MsgList> {
  Messages _msg = Messages.instance;
  ParseService _b4a = ParseService();

  @override
  initState() {
    super.initState();
    print('MsgList initState() activated');
    // _msg.buildMockList();
    print(_msg.messages?.length);
  }

  @override
  Widget build(BuildContext context) {
    // final brews = Provider.of<List<Brew>>(context) ?? [];

    return ListView.separated(
        separatorBuilder: (context, index) => Divider(
              color: Color(0xFF167F67),
            ),
        padding: const EdgeInsets.all(1.0),
        itemCount: null == _msg.messages ? 0 : _msg.messages.length,
        itemBuilder: /*1*/ (context, i) {
          return _buildRow(_msg.messages[i]);
        });
  }

  Widget _buildRow(NotyMessage message) {
    return ListTile(
      onLongPress: () async {
        final bool action = await _deleteConfirmAlert(context);
        if (action) {
          setState(() {
            var id = message.objectId;
            print(id);
            _msg.deleteMessageLocalyId(id);
            _b4a.deleteByObjectID('Messages', id);
          });
        }
      },
      title: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                child: Text(
                  'from: ${message.from}' ?? 'null',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Spacer(),
              Container(
                child: Text(
                  message.timestamp ?? 'null',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                // formatDate(message.timestamp, dateformat).toString()),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  message.body ?? 'null',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 5,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<bool> _deleteConfirmAlert(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete meesage!'),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            FlatButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}
