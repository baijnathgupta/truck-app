import 'package:flutter/material.dart';
import '../services/api.dart';
import 'trip_create_screen.dart';
class TripsScreen extends StatefulWidget{final String token;final String role;const TripsScreen({super.key,required this.token,required this.role});@override State<TripsScreen> createState()=>_S();}
class _S extends State<TripsScreen>{
 List trips=[];bool loading=true;
 @override void initState(){super.initState();load();}
 Future<void> load()async{setState(()=>loading=true);final r=await Api.trips(widget.token);setState(()=>{trips=r['trips']??[],loading=false});}
 @override Widget build(BuildContext c)=>Scaffold(
   appBar:AppBar(title:const Text('Trips')),
   floatingActionButton:FloatingActionButton(onPressed:()async{
     final added=await Navigator.push(c,MaterialPageRoute(builder:(_)=>TripCreateScreen(token:widget.token,role:widget.role)));
     if(added==true) load();
   },child:const Icon(Icons.add)),
   body:loading?const Center(child:CircularProgressIndicator()):trips.isEmpty?const Center(child:Text('No trips yet')):
   ListView.builder(itemCount:trips.length,itemBuilder:(_,i){final t=trips[i];
     return Card(margin:const EdgeInsets.symmetric(horizontal:12,vertical:6),child:ListTile(
       leading:const Icon(Icons.route),
       title:Text('${t['trip_number']} · ${t['source']} → ${t['destination']}'),
       subtitle:Text('Truck: ${t['truck_number']??'-'}  Driver: ${t['driver_name']??'-'}'),
       trailing:Text(t['status']??''),
     ));
   }));
}
