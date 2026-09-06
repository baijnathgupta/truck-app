import 'package:flutter/material.dart';
import '../services/api.dart';
class DriverScreen extends StatefulWidget{final String token;const DriverScreen({super.key,required this.token});@override State<DriverScreen> createState()=>_S();}
class _S extends State<DriverScreen>{
 List drivers=[];bool loading=true;
 @override void initState(){super.initState();load();}
 Future<void> load()async{setState(()=>loading=true);final r=await Api.drivers(widget.token);setState(()=>{drivers=r['drivers']??[],loading=false});}
 Future<void> addDriver()async{
   final name=TextEditingController(),phone=TextEditingController(),password=TextEditingController();
   final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Add Driver'),content:Column(mainAxisSize:MainAxisSize.min,children:[
     TextField(controller:name,decoration:const InputDecoration(labelText:'Name')),
     TextField(controller:phone,decoration:const InputDecoration(labelText:'Phone')),
     TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Password')),
   ]),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),
     FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Add'))]));
   if(ok==true && name.text.isNotEmpty && phone.text.isNotEmpty && password.text.isNotEmpty){
     final r=await Api.createDriver(widget.token,name.text,phone.text,password.text);
     if(r['success']==true) load();
     else if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']??'Failed to add driver')));
   }
 }
 @override Widget build(BuildContext c)=>Scaffold(
   appBar:AppBar(title:const Text('Drivers')),
   floatingActionButton:FloatingActionButton(onPressed:addDriver,child:const Icon(Icons.add)),
   body:loading?const Center(child:CircularProgressIndicator()):drivers.isEmpty?const Center(child:Text('No drivers yet')):
   ListView.builder(itemCount:drivers.length,itemBuilder:(_,i){final d=drivers[i];
     return Card(margin:const EdgeInsets.symmetric(horizontal:12,vertical:6),child:ListTile(
       leading:const Icon(Icons.person),
       title:Text(d['name']??''),
       subtitle:Text(d['phone']??''),
     ));
   }));
}
