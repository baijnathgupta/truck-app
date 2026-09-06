import 'package:flutter/material.dart';
import '../services/api.dart';
class TruckScreen extends StatefulWidget{final String token;const TruckScreen({super.key,required this.token});@override State<TruckScreen> createState()=>_S();}
class _S extends State<TruckScreen>{
 List trucks=[];bool loading=true;
 @override void initState(){super.initState();load();}
 Future<void> load()async{setState(()=>loading=true);final r=await Api.trucks(widget.token);setState(()=>{trucks=r['trucks']??[],loading=false});}
 Future<void> addTruck()async{
   final number=TextEditingController(),model=TextEditingController(),capacity=TextEditingController();
   final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Add Truck'),content:Column(mainAxisSize:MainAxisSize.min,children:[
     TextField(controller:number,decoration:const InputDecoration(labelText:'Truck Number')),
     TextField(controller:model,decoration:const InputDecoration(labelText:'Model')),
     TextField(controller:capacity,decoration:const InputDecoration(labelText:'Capacity')),
   ]),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),
     FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Add'))]));
   if(ok==true && number.text.isNotEmpty){
     final r=await Api.createTruck(widget.token,number.text,model.text,capacity.text);
     if(r['success']==true) load();
     else if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']??'Failed to add truck')));
   }
 }
 @override Widget build(BuildContext c)=>Scaffold(
   appBar:AppBar(title:const Text('Trucks')),
   floatingActionButton:FloatingActionButton(onPressed:addTruck,child:const Icon(Icons.add)),
   body:loading?const Center(child:CircularProgressIndicator()):trucks.isEmpty?const Center(child:Text('No trucks yet')):
   ListView.builder(itemCount:trucks.length,itemBuilder:(_,i){final t=trucks[i];
     return Card(margin:const EdgeInsets.symmetric(horizontal:12,vertical:6),child:ListTile(
       leading: const Icon(Icons.local_shipping),
       title:Text(t['number']??''),
       subtitle:Text('${t['model']??''} · ${t['capacity']??''}'),
       trailing:Text(t['status']??''),
     ));
   }));
}
