import 'package:flutter/material.dart';
import '../services/api.dart';
import 'trip_create_screen.dart';
import 'expenses_screen.dart';
class TripsScreen extends StatefulWidget{final String token;final String role;const TripsScreen({super.key,required this.token,required this.role});@override State<TripsScreen> createState()=>_S();}
class _S extends State<TripsScreen>{
 List trips=[];bool loading=true;
 bool get _isOwner=>widget.role=='OWNER'||widget.role=='ADMIN';
 @override void initState(){super.initState();load();}
 Future<void> load()async{setState(()=>loading=true);final r=await Api.trips(widget.token);setState(()=>{trips=r['trips']??[],loading=false});}

 Future<void> complete(int id)async{
   final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Complete Trip'),
     content:const Text('Mark this trip as completed? This frees up its truck for a new trip.'),
     actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),
       FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Complete'))]));
   if(ok==true){
     final r=await Api.completeTrip(widget.token,id);
     if(r['success']==true) load();
     else if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']??'Failed to complete trip')));
   }
 }

 @override Widget build(BuildContext c){
   final active=trips.where((t)=>t['status']!='COMPLETED').toList();
   final completed=trips.where((t)=>t['status']=='COMPLETED').toList();
   return Scaffold(
     appBar:AppBar(title:const Text('Trips')),
     floatingActionButton:_isOwner?FloatingActionButton(onPressed:()async{
       final added=await Navigator.push(c,MaterialPageRoute(builder:(_)=>TripCreateScreen(token:widget.token,role:widget.role)));
       if(added==true) load();
     },child:const Icon(Icons.add)):null,
     body:loading?const Center(child:CircularProgressIndicator()):trips.isEmpty?const Center(child:Text('No trips yet')):
     RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.only(bottom:16),children:[
       Padding(padding:const EdgeInsets.fromLTRB(16,16,16,4),child:Text('Active Trips (${active.length})',style:const TextStyle(fontSize:16,fontWeight:FontWeight.bold))),
       if(active.isEmpty) const Padding(padding:EdgeInsets.symmetric(horizontal:16),child:Text('No active trips')),
       ...active.map((t)=>_tripCard(c,t,showComplete:true)),
       Padding(padding:const EdgeInsets.fromLTRB(16,16,16,4),child:Text('Completed Trips (${completed.length})',style:const TextStyle(fontSize:16,fontWeight:FontWeight.bold))),
       if(completed.isEmpty) const Padding(padding:EdgeInsets.symmetric(horizontal:16),child:Text('No completed trips')),
       ...completed.map((t)=>_tripCard(c,t,showComplete:false)),
     ])));
 }

 Widget _tripCard(BuildContext c,Map t,{required bool showComplete})=>Card(margin:const EdgeInsets.symmetric(horizontal:12,vertical:6),child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   ListTile(
     contentPadding:EdgeInsets.zero,
     leading:const Icon(Icons.route),
     title:Text('${t['trip_number']} · ${t['source']} → ${t['destination']}'),
     subtitle:Text('Truck: ${t['truck_number']??'-'}  Driver: ${t['driver_name']??'-'}'),
     trailing:Text(t['status']??''),
     onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>ExpensesScreen(
       token:widget.token,role:widget.role,tripId:t['id'],tripLabel:t['trip_number']))),
   ),
   if(showComplete && _isOwner) Align(alignment:Alignment.centerRight,child:OutlinedButton(onPressed:()=>complete(t['id']),child:const Text('Mark Completed'))),
 ])));
}
