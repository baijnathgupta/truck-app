import 'package:flutter/material.dart';
import 'voice_expense_screen.dart';
import 'truck_screen.dart';
import 'driver_screen.dart';
import 'trips_screen.dart';
import 'login_screen.dart';
import '../services/session.dart';
class DashboardScreen extends StatelessWidget{
 final String token;final Map user;
 const DashboardScreen({super.key,required this.token,required this.user});
 Future<void> _logout(BuildContext c)async{
   await Session.clear();
   if(c.mounted) Navigator.pushAndRemoveUntil(c,MaterialPageRoute(builder:(_)=>const LoginScreen()),(_)=>false);
 }
 @override Widget build(BuildContext c){
   final isOwner=user['role']=='OWNER'||user['role']=='ADMIN';
   return Scaffold(appBar:AppBar(title:Text('Hello ${user['name']}'),actions:[
     IconButton(onPressed:()=>_logout(c),icon:const Icon(Icons.logout)),
   ]),
   body:ListView(padding:const EdgeInsets.all(16),children:[
     Text(isOwner?'Owner Dashboard':'Driver Dashboard',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
     const SizedBox(height:12),
     if(isOwner) ...[
       _tile(c,'Trucks',Icons.local_shipping,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>TruckScreen(token:token)))),
       _tile(c,'Drivers',Icons.people,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>DriverScreen(token:token)))),
     ],
     _tile(c,'Trips',Icons.route,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>TripsScreen(token:token,role:user['role'])))),
     _tile(c,'Add Expense by Voice',Icons.mic,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>VoiceExpenseScreen(token:token)))),
   ]));
 }
}
Widget _tile(BuildContext c,String label,IconData icon,VoidCallback onTap)=>Card(child:ListTile(leading:Icon(icon,size:30),title:Text(label),trailing:const Icon(Icons.chevron_right),onTap:onTap));
