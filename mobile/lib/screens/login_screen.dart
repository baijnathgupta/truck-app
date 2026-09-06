import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/session.dart';
import 'dashboard_screen.dart';
class LoginScreen extends StatefulWidget{const LoginScreen({super.key});@override State<LoginScreen> createState()=>_S();}
class _S extends State<LoginScreen>{
 final phone=TextEditingController(),pass=TextEditingController();bool loading=false;
 void login()async{setState(()=>loading=true);final r=await Api.login(phone.text,pass.text);setState(()=>loading=false);
 if(r['success']==true && mounted){
   await Session.save(r['token'],r['user']);
   if(mounted) Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>DashboardScreen(token:r['token'],user:r['user'])));
 } else if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']??'Login failed')));}
 @override Widget build(BuildContext c)=>Scaffold(body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(children:[
 const Icon(Icons.local_shipping,size:80),const SizedBox(height:20),const Text('Truck Trip Management',style:TextStyle(fontSize:25,fontWeight:FontWeight.bold)),
 TextField(controller:phone,decoration:const InputDecoration(labelText:'Phone')),TextField(controller:pass,obscureText:true,decoration:const InputDecoration(labelText:'Password')),
 const SizedBox(height:20),FilledButton(onPressed:loading?null:login,child:Text(loading?'Loading...':'Login'))
 ]))));}
