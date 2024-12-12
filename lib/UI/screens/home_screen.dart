import 'package:dipsy/UI/screens/client/tv_screen.dart';
import 'package:dipsy/UI/screens/dashboard/dashboard.dart';
import 'package:dipsy/UI/screens/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoggedIn=false;
  bool isLoading=true;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkLoginStatus();
  }

  checkLoginStatus()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    String xapi= prefs.getString("x-api-key")??"";
    if(xapi!=""){
      isLoggedIn=true;
    }
    setState(() {
      isLoading=false;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading?Center(child: CircularProgressIndicator()): isLoggedIn? LoginScreen():DashboardScreen());
  }
}