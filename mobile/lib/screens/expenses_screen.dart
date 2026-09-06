import 'package:flutter/material.dart';
import '../services/api.dart';
class ExpensesScreen extends StatefulWidget{final String token;final String role;final int? tripId;final String? tripLabel;final int? truckId;final String? truckLabel;
 const ExpensesScreen({super.key,required this.token,required this.role,this.tripId,this.tripLabel,this.truckId,this.truckLabel});
 @override State<ExpensesScreen> createState()=>_S();}
class _S extends State<ExpensesScreen>{
 List expenses=[];bool loading=true;
 @override void initState(){super.initState();load();}
 Future<void> load()async{setState(()=>loading=true);final r=await Api.expenses(widget.token,tripId:widget.tripId,truckId:widget.truckId);setState(()=>{expenses=r['expenses']??[],loading=false});}

 String _fmt(String? iso){
   if(iso==null) return '';
   final d=DateTime.tryParse(iso);
   if(d==null) return iso;
   final l=d.toLocal();
   String two(int n)=>n.toString().padLeft(2,'0');
   return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
 }

 Future<void> approve(int id)async{
   final r=await Api.approveExpense(widget.token,id);
   if(r['success']==true) load();
   else if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']??'Failed to approve')));
 }

 Future<void> reject(int id)async{
   final reason=TextEditingController();
   final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Reject Expense'),
     content:TextField(controller:reason,decoration:const InputDecoration(labelText:'Reason')),
     actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),
       FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Reject'))]));
   if(ok==true){
     final r=await Api.rejectExpense(widget.token,id,reason.text.isEmpty?'Rejected by owner':reason.text);
     if(r['success']==true) load();
     else if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']??'Failed to reject')));
   }
 }

 Color _statusColor(String s)=>s=='APPROVED'?Colors.green:s=='REJECTED'?Colors.red:Colors.orange;

 @override Widget build(BuildContext c){
   final isOwner=widget.role=='OWNER'||widget.role=='ADMIN';
   return Scaffold(
     appBar:AppBar(title:Text(widget.tripLabel!=null?'Expenses · ${widget.tripLabel}':widget.truckLabel!=null?'Expenses · ${widget.truckLabel}':'Expenses')),
     body:loading?const Center(child:CircularProgressIndicator()):expenses.isEmpty?const Center(child:Text('No expenses yet')):
     RefreshIndicator(onRefresh:load,child:ListView.builder(itemCount:expenses.length,itemBuilder:(_,i){final e=expenses[i];
       final status=e['status']??'PENDING';
       return Card(margin:const EdgeInsets.symmetric(horizontal:12,vertical:6),child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
         Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
           Text('₹${e['amount']}',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
           Chip(label:Text(status),backgroundColor:_statusColor(status).withValues(alpha:0.15),labelStyle:TextStyle(color:_statusColor(status))),
         ]),
         const SizedBox(height:4),
         Text('Trip: ${e['trip_number']??'-'}  ·  By: ${e['created_by_name']??'-'}'),
         Text(_fmt(e['created_at']),style:TextStyle(color:Colors.grey.shade600,fontSize:12)),
         if((e['category']??'').toString().isNotEmpty) Text('Category: ${e['category']}'),
         if((e['description']??'').toString().isNotEmpty) Text(e['description']),
         if(isOwner && status=='PENDING') Padding(padding:const EdgeInsets.only(top:8),child:Row(children:[
           FilledButton(onPressed:()=>approve(e['id']),child:const Text('Approve')),
           const SizedBox(width:8),
           OutlinedButton(onPressed:()=>reject(e['id']),child:const Text('Reject')),
         ])),
       ])));
     })));
 }
}
