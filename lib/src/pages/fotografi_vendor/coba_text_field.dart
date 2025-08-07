import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


// Global Variable
var kodeSalesLoginGlobal = '';
var namaSalesLoginGlobal = '';
var areaSalesLoginGlobal = '';
var emailSalesLoginGlobal = '';
var cabangSalesLoginGlobal = '';

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> get _localFile async {
  final path = await _localPath;
  return File('$path/phonedata.txt');
}

Future<File> writeContent(email, pass) async {
  final file = await _localFile;
  // Write the file
  return file.writeAsString(email + "," + pass);
}

class CobaTextField extends StatefulWidget {
  const CobaTextField({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CobaTextFieldState createState() => _CobaTextFieldState();
}

class _CobaTextFieldState extends State<CobaTextField> {
  late FocusNode _namaFocus;
  late FocusNode _sandiFocus;

  late TextEditingController _email, _passWord;

  @override
  initState() {
    _email = TextEditingController();
    _passWord = TextEditingController();

    _email.text = '';
    _passWord.text = '';

    _namaFocus = FocusNode();
    _sandiFocus = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _namaFocus.dispose();
    _sandiFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false, // No Back Button Pressed
        child: Scaffold(
         
          body: Stack(
            children: <Widget>[
             
              ListView(
                padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                children: <Widget>[
                  SizedBox(
                    height: 450,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        
                        Card(
                          margin: const EdgeInsets.only(
                              left: 15, right: 15, top: 30),
                          elevation: 11,
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(40))),
                          child: TextField(
                            autofocus: false,
                            controller: _email,
                            focusNode: _namaFocus,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (term) {
                              _fieldFocusChange(
                                  context, _namaFocus, _sandiFocus);
                            },
                            decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.person,
                                  color: Colors.black54,
                                ),
                                suffixIcon: IconButton(
                                    alignment: Alignment.centerRight,
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _email.text = "";
                                      });
                                    }),
                                hintText: "Email Anda",
                                hintStyle:
                                    const TextStyle(color: Colors.black54),
                                filled: true,
                                fillColor: Colors.white,
                                border: const OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20.0, vertical: 16.0)),
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.only(
                              left: 15, right: 15, top: 20),
                          elevation: 11,
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(40))),
                          child: TextField(
                              controller: _passWord,
                              obscureText: true,
                              focusNode: _sandiFocus,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    Icons.lock,
                                    color: Colors.black54,
                                  ),
                                  suffixIcon: IconButton(
                                    alignment: Alignment.centerRight,
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _passWord.text = "";
                                      });
                                    },
                                  ),
                                  hintText: "Sandi ",
                                  hintStyle: const TextStyle(
                                    color: Colors.black54,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: const OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 16.0))),
                        ),
                      
                       
                        
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}

// Focus & UnFocus
_fieldFocusChange(
    BuildContext context, FocusNode currentFocus, FocusNode nextFocus) {
  currentFocus.unfocus();
  FocusScope.of(context).requestFocus(nextFocus);
}
