import 'package:flutter/material.dart';
import '../services/api.dart';
import 'expenses_screen.dart';
class TruckScreen extends StatefulWidget{final String token;final String role;const TruckScreen({super.key,required this.token,required this.role});@override State<TruckScreen> createState()=>_S();}
class _S extends State<TruckScreen>{
 List trucks=[],drivers=[];bool loading=true;
 @override void initState(){super.initState();load();}
 Future<void> load()async{
   setState(()=>loading=true);
   final t=await Api.trucks(widget.token);
   final d=await Api.drivers(widget.token);
   setState(()=>{trucks=t['trucks']??[],drivers=d['drivers']??[],loading=false});
 }
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

 Future<void> assignDriver(Map truck)async{
   final assignedIds=trucks.where((t)=>t['id']!=truck['id'] && t['driver_id']!=null).map((t)=>t['driver_id']).toSet();
   final available=drivers.where((d)=>!assignedIds.contains(d['id'])).toList();
   int? selected=truck['driver_id'];
   final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
     title:const Text('Assign Driver'),
     content:DropdownButtonFormField<int>(
       initialValue:selected,decoration:const InputDecoration(labelText:'Driver'),
       items:[
         const DropdownMenuItem<int>(value:null,child:Text('Unassigned')),
         ...available.map<DropdownMenuItem<int>>((d)=>DropdownMenuItem(value:d['id'],child:Text(d['name']))),
       ],
       onChanged:(v)=>setD(()=>selected=v),
     ),
     actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),
       FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Save'))],
   )));
   if(ok==true){
     final r=await Api.assignDriver(widget.token,truck['id'],selected);
     if(r['success']==true) load();
     else if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']??'Failed to assign driver')));
   }
 }

 @override Widget build(BuildContext c)=>Scaffold(
   appBar:AppBar(title:const Text('Trucks')),
   floatingActionButton:FloatingActionButton(onPressed:addTruck,child:const Icon(Icons.add)),
   body:loading?const Center(child:CircularProgressIndicator()):trucks.isEmpty?const Center(child:Text('No trucks yet')):
   RefreshIndicator(onRefresh:load,child:ListView.builder(itemCount:trucks.length,itemBuilder:(_,i){final t=trucks[i];
     return Card(margin:const EdgeInsets.symmetric(horizontal:12,vertical:6),child:ListTile(
       leading: const Icon(Icons.local_shipping),
       title:Text(t['number']??''),
       subtitle:Text('${t['model']??''} · ${t['capacity']??''}\nDriver: ${t['driver_name']??'Unassigned'}'),
       isThreeLine:true,
       trailing:IconButton(icon:const Icon(Icons.person_add),tooltip:'Assign Driver',onPressed:()=>assignDriver(t)),
       onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>ExpensesScreen(
         token:widget.token,role:widget.role,truckId:t['id'],truckLabel:t['number']))),
     ));
   })));
}
