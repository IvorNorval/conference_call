import 'package:conference_call/screens/login_screen.dart';
import 'package:connectycube_sdk/connectycube_sdk.dart';
import 'package:flutter/material.dart';

import 'utils/configs.dart' as config;

void main() => runApp(App());

class App extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AppState();
  }
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: LoginScreen.id,
      routes: {
        LoginScreen.id: (context) => LoginScreen(),
      },
    );
  }

  @override
  void initState() {
    super.initState();
    init(
      config.APP_ID,
      config.AUTH_KEY,
      config.AUTH_SECRET,
    );
  }
}
