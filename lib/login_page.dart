import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/service_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String name = '';
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isShowPassword = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          actions: [],
          backgroundColor: Colors.white,
          title: const Text(
            "ESCA HRIS",
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                padding: const EdgeInsets.all(16),
                child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Image.asset(
                          "assets/login_icon.png",
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Text(
                      'Silakan masuk untuk menggunakan aplikasi ini',
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 30),
                      child: TextFormField(
                        validator: (value) {
                          String pattern =
                              r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                          RegExp regex = new RegExp(pattern);
                          if (!regex.hasMatch(value!))
                            return 'Not a valid email';
                          else
                            return null;
                        },
                        controller: _emailController,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          labelText: 'Email',
                          hintText: 'Masukkan alamat E-Mail Anda',
                        ),
                      ),
                    ),
                    Container(
                        margin: const EdgeInsets.only(top: 10),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: !_isShowPassword,
                          validator: (value) => value!.length < 8
                              ? 'Password must be at least 8 characters'
                              : null,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            labelText: 'Password',
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isShowPassword = !_isShowPassword;
                                });
                              },
                              child: Icon(
                                _isShowPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                        )),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          child: const Text('Lupa password Anda?'),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          child: const Text(
                            ' Klik sini',
                            style: TextStyle(
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 40),
                      child: ElevatedButton(
                          onPressed: () async {
                            await login(_emailController.text,
                                _passwordController.text);
                          },
                          child: Text("Login")),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 15),
                      child: TextButton(
                        onPressed: () {

                        },
                        child: const Text('Ganti URL', style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.blue,
                        ))
                      ),
                    ),
                  ],
                ),
              )),
        //   <--- image
      ),
    );
  }

  Future<void> login(String email, String password) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        var res = await ServiceConfig().login(email, password);

        if (res is String) {
          setState(() {
            _isLoading = false;
          });
          final snackBar = SnackBar(
            content: Text(
              res,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          );
          ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(snackBar);
          return;
        }

        var response = jsonDecode(res.body);

        if (res.statusCode == 200) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', response['token']);

          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const HomePage()));
        } else {
          var error = response['meta']['error'];
          print(error);
          final snackBar = SnackBar(
            content: Text(
              error,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          );
          ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(snackBar);
        }
      } catch (e) {
        print(e.toString());
      }
      setState(() {
        _isLoading = false;
      });
    }
  }
}
