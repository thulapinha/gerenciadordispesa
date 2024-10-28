import 'package:flutter/material.dart';
import 'package:metroni/Home/home.dart';
import 'package:metroni/Registro/registro.dart';
import 'package:metroni/recupera_senha/recuperar_senha.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const keyApplicationId = '1GyULnDwmyAt5tmG71zvg6Vhgh8iDP918jgXx0r7';
  const keyClientKey = 'zRSqivIu8SLqjTqnvEZNmOdzslRZimbrvkIY79XN';
  const keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl, clientKey: keyClientKey, autoSendSessionId: true);

  final currentUser = await ParseUser.currentUser() as ParseUser?;
  runApp(MyApp(currentUser: currentUser));
}

class MyApp extends StatelessWidget {
  final ParseUser? currentUser;

  MyApp({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Parse Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: currentUser != null ? HomePage(user: currentUser!) : LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  void _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor, preencha todos os campos')));
      return;
    }

    final user = ParseUser(username, password, null);
    final response = await user.login();

    if (response.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(user: user)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error!.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
              obscureText: _obscureText,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            SizedBox(height: 8.0),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              child: Text('Não tem uma conta? Registre-se'),
            ),
            SizedBox(height: 8.0),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                );
              },
              child: Text('Esqueci a Senha'),
            ),
          ],
        ),
      ),
    );
  }
}
