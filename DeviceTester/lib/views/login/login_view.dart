import 'package:devicetester/models/app_constants.dart';
import 'package:devicetester/models/auth/auth_helper.dart';
import 'package:devicetester/views/test/test_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginView extends StatelessWidget {
  LoginView({Key? key}) : super(key: key);
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final usernameController = TextEditingController();
    final passController = TextEditingController();
    return Scaffold(
      backgroundColor: primarySwatch.entries.last.value,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        "Device Tester'a Hoş Geldiniz!",
                        style: TextStyle(
                          fontSize: 25,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                buildTextField(usernameController, 'E-Mail'),
                SizedBox(height: 10),
                buildTextField(passController, 'Şifre', obsecureText: true),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () async {
                    showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          return Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white));
                        });
                    await FirebaseAuthHelper.instance
                        .signIn(
                            email: usernameController.text.trim(),
                            password: passController.text.trim())
                        .then((value) {
                      Navigator.pop(context);
                      if (value is String) {
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  title: Text(value),
                                  actions: [
                                    TextButton(
                                      child: Text('Tamam'),
                                      onPressed: () => Navigator.pop(context),
                                    )
                                  ],
                                ));
                      } else {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => TestView()),
                            (route) => false);
                      }
                    });
                  },
                  child:
                      Text('Giriş Yap', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                      side: BorderSide(color: Colors.white),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextFormField buildTextField(TextEditingController usernameController, label,
      {obsecureText = false}) {
    return TextFormField(
      controller: usernameController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Bu alan boş bırakılamaz';
        }
        return null;
      },
      cursorColor: Colors.white,
      style: TextStyle(color: Colors.white),
      obscureText: obsecureText,
      decoration: InputDecoration(
        label: Text(label, style: TextStyle(color: Colors.white)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}
