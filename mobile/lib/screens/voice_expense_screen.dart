import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/api.dart';
class VoiceExpenseScreen extends StatefulWidget{final String token;const VoiceExpenseScreen({super.key,required this.token});@override State<VoiceExpenseScreen> createState()=>_S();}
class _S extends State<VoiceExpenseScreen>{
 final speech=stt.SpeechToText();String text='';bool listening=false,saving=false,loadingTrips=true;
 final amount=TextEditingController();
 List trips=[];int? tripId;
 @override void initState(){super.initState();loadTrips();}
 Future<void> loadTrips()async{final r=await Api.trips(widget.token);setState(()=>{trips=r['trips']??[],loadingTrips=false});}
 Future<void> start()async{final ok=await speech.initialize();if(!ok)return;setState(()=>listening=true);speech.listen(onResult:(r)=>setState(()=>text=r.recognizedWords));}
 void stop(){speech.stop();setState(()=>listening=false);}
 Future<void> confirm()async{
   if(tripId==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Select a trip first')));return;}
   final amt=double.tryParse(amount.text);
   if(amt==null||amt<=0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter a valid amount')));return;}
   setState(()=>saving=true);
   final r=await Api.createExpense(widget.token,{'tripId':tripId,'categoryId':null,'amount':amt,'description':text,'voiceText':text});
   setState(()=>saving=false);
   if(r['success']==true && mounted){
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Expense saved')));
     Navigator.pop(context,true);
   } else if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']??'Failed to save expense')));
 }
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Voice Expense')),body:loadingTrips?const Center(child:CircularProgressIndicator()):Padding(padding:const EdgeInsets.all(20),child:Column(children:[
 const Text('Speak your expense',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),
 const SizedBox(height:20),Icon(listening?Icons.mic:Icons.mic_none,size:100),
 const SizedBox(height:12),Text(text.isEmpty?'Example: Diesel 3500 rupees at Jaipur':text),
 const SizedBox(height:16),FilledButton.icon(onPressed:listening?stop:start,icon:Icon(listening?Icons.stop:Icons.mic),label:Text(listening?'Stop':'Start Recording')),
 const SizedBox(height:16),DropdownButtonFormField<int>(
   initialValue:tripId,decoration:const InputDecoration(labelText:'Trip'),
   items:trips.map<DropdownMenuItem<int>>((t)=>DropdownMenuItem(value:t['id'],child:Text(t['trip_number']))).toList(),
   onChanged:(v)=>setState(()=>tripId=v)),
 const SizedBox(height:12),TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Amount')),
 const Spacer(),
 OutlinedButton(onPressed:saving?null:confirm,child:Text(saving?'Saving...':'Confirm Expense'))
 ])));
}
