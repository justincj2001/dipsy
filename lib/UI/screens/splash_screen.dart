import 'package:dipsy/UI/screens/home_screen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    waitForSomeTime(Duration(seconds: 3));
  }

  waitForSomeTime(Duration time)async{
    await Future.delayed(time);
    Navigator.push(context, MaterialPageRoute(builder: (context)=>HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 40, 40, 40),
      body: Center(child: Text("DIPSY",style: TextStyle(color: const Color.fromARGB(255, 255, 122, 122),fontSize: 30,fontFamily: "Sofia"),)),);
  }
}