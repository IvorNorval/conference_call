import 'package:conference_call/utils/call_manager.dart';
import 'package:conference_call/utils/configs.dart' as configs;
import 'package:connectycube_sdk/connectycube_calls.dart';
import 'package:connectycube_sdk/connectycube_chat.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'call_screen.dart';

class ContactList extends StatefulWidget {
  static const String id = 'ContactList';
  final CubeUser currentUser;
  const ContactList(this.currentUser);

  @override
  _ContactListState createState() => _ContactListState(currentUser);
}

class _ContactListState extends State<ContactList> {
  Set<CubeUser> contactList = {};
  Set<int> _selectedUsers = {};
  final TextEditingController _idFilter = TextEditingController();
  CubeUser currentUser = CubeUser();
  String _id = "";
  String joinRoomId;
  CallManager _callManager;
  ConferenceClient _callClient;
  ConferenceSession _currentCall;

  _ContactListState(this.currentUser) {
    _idFilter.addListener(_idListen);
  }

  void _idListen() {
    if (_idFilter.text.isEmpty) {
      _id = "";
    } else {
      _id = _idFilter.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('ID: ${currentUser.id} (copied to clipboard)'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _idFilter,
              decoration: InputDecoration(labelText: 'Id'),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RaisedButton(
                child: Text('Get Contact'),
                onPressed: _getUserById,
              ),
              SizedBox(
                width: 30,
              ),
              RaisedButton(
                child: Text('Log out'),
                onPressed: _logout,
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Expanded(
            child: _getOpponentsList(context),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FloatingActionButton(
                heroTag: "VideoCall",
                child: Icon(
                  Icons.videocam,
                  color: Colors.white,
                ),
                backgroundColor: Colors.blue,
                onPressed: () => _startCall(_selectedUsers),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _getUserById() {
    getUserById(int.parse(_id)).then((cubeUser) {
      setState(() {
        contactList.add(cubeUser);
        _id = "";
        FocusScope.of(context).requestFocus(FocusNode());
      });
    }).catchError((error) {});
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Logout"),
          content: Text("Are you sure you want logout current user"),
          actions: <Widget>[
            FlatButton(
              child: Text("CANCEL"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            FlatButton(
              child: Text("OK"),
              onPressed: () {
                signOut().then(
                  (voidValue) {
                    CubeChatConnection.instance.destroy();
                    Navigator.pop(context, true);
                    Navigator.pop(context, true);
                  },
                ).catchError(
                  (onError) {
                    Navigator.pop(context, true);
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _getOpponentsList(BuildContext context) {
    CubeUser currentUser = CubeChatConnection.instance.currentUser;
    final users = contactList.where((user) => user.id != currentUser.id).toList();
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        return Card(
          child: CheckboxListTile(
            title: Center(
              child: Text(
                users[index].fullName,
              ),
            ),
            value: _selectedUsers.contains(users[index].id),
            onChanged: ((checked) {
              setState(() {
                if (checked) {
                  _selectedUsers.add(users[index].id);
                } else {
                  _selectedUsers.remove(users[index].id);
                }
              });
            }),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _initConferenceConfig();
    _initCalls();
    CubeUser currentUser = CubeChatConnection.instance.currentUser;
    joinRoomId = currentUser.id.toString();
  }

  void _initCalls() {
    _callClient = ConferenceClient.instance;
    _callManager = CallManager.instance;
    _callManager.onReceiveNewCall = (roomId, participantIds) {
      _showIncomingCallScreen(roomId, participantIds);
    };
    _callManager.onCloseCall = () {
      _currentCall = null;
    };
  }

  void _startCall(Set<int> opponents) async {
    if (opponents.isEmpty) return;
    CubeUser currentUser = CubeChatConnection.instance.currentUser;
    _currentCall = await _callClient.createCallSession(currentUser.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationCallScreen(_currentCall, joinRoomId, opponents.toList(), false),
      ),
    );
  }

  void _showIncomingCallScreen(String roomId, List<int> participantIds) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncomingCallScreen(roomId, participantIds),
      ),
    );
  }

  void _initConferenceConfig() {
    ConferenceConfig.instance.url = configs.SERVER_ENDPOINT;
  }
}
