import 'package:flutter/material.dart';
import '../services/api.dart';
class TripCreateScreen extends StatefulWidget{final String token;final String role;const TripCreateScreen({super.key,required this.token,required this.role});@override State<TripCreateScreen> createState()=>_S();}
class _S extends State<TripCreateScreen>{
 final tripNumber=TextEditingController(),source=TextEditingController(),destination=TextEditingController(),
   goodsType=TextEditingController(),weight=TextEditingController(),freight=TextEditingController(),advance=TextEditingController();
 List trucks=[];int? truckId;bool loading=false,loadingLists=true;

 @override void initState(){super.initState();loadLists();}
 Future<void> loadLists()async{
   final t=await Api.trucks(widget.token);
   setState(()=>{trucks=t['trucks']??[],loadingLists=false});
 }

 Future<void> submit()async{
   if(tripNumber.text.isEmpty||source.text.isEmpty||destination.text.isEmpty){
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Trip number, source and destination are required')));
     return;
   }
   if(truckId==null){
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Select a truck')));
     return;
   }
   setState(()=>loading=true);
   final r=await Api.createTrip(widget.token,{
     'tripNumber':tripNumber.text,'source':source.text,'destination':destination.text,
     'goodsType':goodsType.text,'weight':weight.text,
     'freight':double.tryParse(freight.text)??0,'advance':double.tryParse(advance.text)??0,
     'truckId':truckId,
     'startDate':DateTime.now().toIso8601String().substring(0,10),
   });
   setState(()=>loading=false);
   if(r['success']==true && mounted) Navigator.pop(context,true);
   else if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']??'Failed to create trip')));
 }

 @override Widget build(BuildContext c){
   final assignedTrucks=trucks.where((t)=>t['driver_id']!=null).toList();
   return Scaffold(
   appBar:AppBar(title:const Text('New Trip')),
   body:loadingLists?const Center(child:CircularProgressIndicator()):SingleChildScrollView(padding:const EdgeInsets.all(16),child:Column(children:[
     TextField(controller:tripNumber,decoration:const InputDecoration(labelText:'Trip Number')),
     TextField(controller:source,decoration:const InputDecoration(labelText:'Source')),
     TextField(controller:destination,decoration:const InputDecoration(labelText:'Destination')),
     TextField(controller:goodsType,decoration:const InputDecoration(labelText:'Goods Type')),
     TextField(controller:weight,decoration:const InputDecoration(labelText:'Weight')),
     TextField(controller:freight,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Freight')),
     TextField(controller:advance,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Advance')),
     const SizedBox(height:12),
     if(assignedTrucks.isEmpty) const Padding(padding:EdgeInsets.symmetric(vertical:8),
       child:Text('No trucks with a driver assigned. Assign a driver to a truck first.',style:TextStyle(color:Colors.red))),
     DropdownButtonFormField<int>(
       initialValue:truckId,decoration:const InputDecoration(labelText:'Truck (driver shown)'),
       items:assignedTrucks.map<DropdownMenuItem<int>>((t)=>DropdownMenuItem(value:t['id'],child:Text('${t['number']} · ${t['driver_name']}'))).toList(),
       onChanged:(v)=>setState(()=>truckId=v)),
     const SizedBox(height:24),
     FilledButton(onPressed:loading?null:submit,child:Text(loading?'Saving...':'Create Trip')),
   ])));
 }
}
