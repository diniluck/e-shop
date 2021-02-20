import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_shop/Widgets/customTextField.dart';
import 'package:e_shop/DialogBox/errorDialog.dart';
import 'package:e_shop/DialogBox/loadingDialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Store/storehome.dart';
import 'package:e_shop/Config/config.dart';



class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}



class _RegisterState extends State<Register> {
  final TextEditingController _nameTextEditingcontroller=TextEditingController();
  final TextEditingController _emailTextEditingcontroller=TextEditingController();
  final TextEditingController _passwordTextEditingcontroller=TextEditingController();
  final TextEditingController _cPasswordTextEditingcontroller=TextEditingController();
  final GlobalKey<FormState> _formKey=GlobalKey<FormState>();
  String userImageUrl="";
  File _imageFile;
  @override
  Widget build(BuildContext context) {
    double _screenWidth=MediaQuery.of(context).size.width, _screenHeight=MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(height: 10.0,),
            InkWell(
              onTap: _selectAndPickImage,
              child: CircleAvatar(
                radius: _screenWidth*0.15,
                backgroundColor: Colors.white,
                backgroundImage: _imageFile==null?null:FileImage(_imageFile),
                child: _imageFile==null
                    ? Icon(Icons.add_photo_alternate,color: Colors.grey,size: _screenWidth*0.15,)
                : null,
              ),
            ),
            SizedBox(height: 8.0,),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextField(
                    controller: _nameTextEditingcontroller,
                    data: Icons.person,
                    hintText: "Name",
                    isObsecure: false,
                  ),
                  CustomTextField(
                    controller: _emailTextEditingcontroller,
                    data: Icons.email,
                    hintText: "Email",
                    isObsecure: false,
                  ),
                  CustomTextField(
                    controller: _passwordTextEditingcontroller,
                    data: Icons.lock,
                    hintText: "Password",
                    isObsecure: true,
                  ),
                  CustomTextField(
                    controller: _cPasswordTextEditingcontroller,
                    data: Icons.lock,
                    hintText: "Confirm Password",
                    isObsecure: true,
                  ),
                ],
              ),
            ),
            RaisedButton(
              onPressed: (){
                uploadAndSaveImage();
              },
              color: Colors.pink,
              child: Text(
                "Sign Up",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 30,),
            Container(
              height: 4.0,
              width: _screenHeight*0.8,
              color: Colors.pink,
            ),
            SizedBox(height: 15.0,),
          ],
        ),
      ),
    );
  }

  Future<void>_selectAndPickImage()async{
    _imageFile=await ImagePicker.pickImage(source: ImageSource.gallery);
  }

  Future<void> uploadAndSaveImage()async {
    if(_imageFile==null){
      showDialog(
        context: context,
        builder: (c){
          return ErrorAlertDialog(
            message: "Please select an image",
          );
        }
      );
    }else{
      _passwordTextEditingcontroller.text==_cPasswordTextEditingcontroller.text
          ? _nameTextEditingcontroller.text.isNotEmpty &&
            _emailTextEditingcontroller.text.isNotEmpty &&
            _passwordTextEditingcontroller.text.isNotEmpty &&
            _cPasswordTextEditingcontroller.text.isNotEmpty
          ? uploadToStorage()

          :displayDialog("Please fill up all the fields")
          :displayDialog("Password do not match");
    }
  }
  displayDialog(String msg){
    showDialog(
      context: context,
      builder: (c){
        return ErrorAlertDialog(message: msg,);
      }
    );
  }

  uploadToStorage() async{
    showDialog(
      context: context,
      builder: (c){
        return LoadingAlertDialog(message: "Registering, Please wait...",);
      }
    );
    String imageFileName=DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference storageReference=FirebaseStorage.instance.ref().child(imageFileName);
    StorageUploadTask storageUploadTask=storageReference.putFile(_imageFile);
    StorageTaskSnapshot taskSnapshot=await storageUploadTask.onComplete;
    await taskSnapshot.ref.getDownloadURL().then((urlImage) {
      userImageUrl=urlImage;
      _registerUser();
    });
  }
  FirebaseAuth _auth =FirebaseAuth.instance;
  void _registerUser()async {
    FirebaseUser firebaseUser;
    await _auth.createUserWithEmailAndPassword(
        email: _emailTextEditingcontroller.text.trim(),
        password: _passwordTextEditingcontroller.text.trim(),
    ).then((_auth){
      firebaseUser=_auth.user;
    }).catchError((error){
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (c){
          return ErrorAlertDialog(message: error.message.toString(),);
        }
      );
    });
    if (firebaseUser !=null){
      saveUserInfoToFireStore(firebaseUser).then((value) {
        Navigator.pop(context);
        Route route=MaterialPageRoute(builder: (c)=>StoreHome());
        Navigator.pushReplacement(context, route);
      });
    }
  }

  Future saveUserInfoToFireStore(FirebaseUser fUser)async {
    Firestore.instance.collection("users").document(fUser.uid).setData({
      "uid":fUser.uid,
      "email":fUser.email,
      "name":_nameTextEditingcontroller.text.trim(),
      "url":userImageUrl,
      EcommerceApp.userCartList:["garbageValue"],
    });
    await EcommerceApp.sharedPreferences.setString("uid", fUser.uid);
    await EcommerceApp.sharedPreferences.setString(EcommerceApp.userEmail, fUser.email);
    await EcommerceApp.sharedPreferences.setString(EcommerceApp.userName, _nameTextEditingcontroller.text);
    await EcommerceApp.sharedPreferences.setString(EcommerceApp.userAvatarUrl, userImageUrl);
    await EcommerceApp.sharedPreferences.setStringList(EcommerceApp.userCartList, ["garbageValue"]);
  }
}

