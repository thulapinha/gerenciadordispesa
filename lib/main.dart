import 'package:flutter/material.dart';
import 'package:metroni/Home/home.dart';
import 'package:metroni/Login/login.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const keyApplicationId = '1GyULnDwmyAt5tmG71zvg6Vhgh8iDP918jgXx0r7';
  const keyClientKey = 'zRSqivIu8SLqjTqnvEZNmOdzslRZimbrvkIY79XN';
  const keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey, autoSendSessionId: true);

  final currentUser = await ParseUser.currentUser() as ParseUser?;
  runApp(MyApp(currentUser: currentUser));
}

class MyApp extends StatelessWidget {
  final ParseUser? currentUser;

  MyApp({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minha agenda',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: currentUser != null ? HomePage(user: currentUser!) : LoginPage(),
    );
  }
}
