import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/session.dart';
void main()=>runApp(const TruckApp());
class TruckApp extends StatelessWidget{
 const TruckApp({super.key});
 @override Widget build(BuildContext context)=>MaterialApp(
   debugShowCheckedModeBanner:false,title:'Truck Trip',
   theme:ThemeData(colorSchemeSeed:Colors.blue,useMaterial3:true),
   home:const SplashScreen());
}
class SplashScreen extends StatefulWidget{const SplashScreen({super.key});@override State<SplashScreen> createState()=>_S();}
class _S extends State<SplashScreen>{
 @override void initState(){super.initState();_check();}
 Future<void> _check()async{
   final session=await Session.load();
   if(!mounted)return;
   Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>session!=null
     ?DashboardScreen(token:session['token'],user:session['user'])
     :const LoginScreen()));
 }
 @override Widget build(BuildContext c)=>const Scaffold(body:Center(child:CircularProgressIndicator()));
}
