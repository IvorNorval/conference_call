import 'package:conference_call/utils/show_dialog_error.dart';
import 'package:connectycube_sdk/connectycube_chat.dart';
import 'package:flutter/material.dart';

import 'contact_list_screen.dart';

class LoginScreen extends StatefulWidget {
  static const String id = 'LoginScreen';

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginFilter = TextEditingController();
  final TextEditingController _passwordFilter = TextEditingController();
  String _login = "";
  String _password = "";
  bool _isLoginContinues = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: BodyLayout(),
    );
  }

  LoginScreenState() {
    _loginFilter.addListener(_loginListen);
    _passwordFilter.addListener(_passwordListen);
  }

  void _passwordListen() {
    if (_passwordFilter.text.isEmpty) {
      _password = "";
    } else {
      _password = _passwordFilter.text;
    }
  }

  void _loginListen() {
    if (_loginFilter.text.isEmpty) {
      _login = "";
    } else {
      _login = _loginFilter.text;
    }
  }

  Widget BodyLayout() {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          _buildTextFields(),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildTextFields() {
    return new Container(
      child: new Column(
        children: <Widget>[
          new Container(
            child: TextField(
              controller: _loginFilter,
              decoration: InputDecoration(labelText: 'Login'),
            ),
          ),
          new Container(
            child: TextField(
              controller: _passwordFilter,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return new Container(
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RaisedButton(
            child: Text('Login'),
            onPressed: _loginPressed,
          ),
          SizedBox(
            width: 30,
          ),
          RaisedButton(
            child: Text('Sign Up'),
            onPressed: _createAccountPressed,
          ),
        ],
      ),
    );
  }

  void _loginPressed() {
    print('login with $_login and $_password');
    _loginToCC(context, CubeUser(login: _login, password: _password), saveUser: true);
  }

  _loginToCC(BuildContext context, CubeUser user, {bool saveUser = false}) {
    if (_isLoginContinues) return;
    setState(() {
      _isLoginContinues = true;
    });

    createSession(user).then((cubeSession) async {
      var tempUser = user;
      user = cubeSession.user..password = tempUser.password;
      _loginToCubeChat(context, user);
    }).catchError(_processLoginError);
  }

  _loginToCubeChat(BuildContext context, CubeUser user) {
    print("_loginToCubeChat user $user");
    CubeChatConnection.instance.login(user).then((cubeUser) {
      _isLoginContinues = false;
      _goDialogScreen(context, cubeUser);
    }).catchError(_processLoginError);
  }

  void _createAccountPressed() {
    print('create an user with $_login and $_password');
    _signInCC(context, CubeUser(login: _login, password: _password, fullName: _login));
  }

  _signInCC(BuildContext context, CubeUser user) async {
    if (_isLoginContinues) return;

    setState(() {
      _isLoginContinues = true;
    });
    if (!CubeSessionManager.instance.isActiveSessionValid()) {
      try {
        await createSession();
      } catch (error) {
        _processLoginError(error);
      }
    }
    signUp(user).then((newUser) {
      print("signUp newUser $newUser");
      user.id = newUser.id;
      signIn(user).then((result) {
        _loginToCubeChat(context, user);
      });
    }).catchError(_processLoginError);
  }

  void _processLoginError(exception) {
    log("Login error $exception", "Login");
    setState(() {
      _isLoginContinues = false;
    });
    showDialogError(exception, context);
  }

  void _goDialogScreen(BuildContext context, CubeUser cubeUser) async {
    bool refresh = await Navigator.push(
      context,
      MaterialPageRoute(
        settings: RouteSettings(name: "/SelectDialogScreen"),
        builder: (context) => ContactList(cubeUser),
      ),
    );
    setState(() {
      if (refresh) {
        _clear();
      }
    });
  }

  void _clear() {
    _isLoginContinues = false;
    _login = "";
    _password = "";
    _loginFilter.clear();
    _passwordFilter.clear();
  }
}
