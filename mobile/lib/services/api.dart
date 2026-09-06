import 'dart:convert';
import 'package:http/http.dart' as http;
class Api {
 static const base='http://localhost:4000/api';

 static Map<String,String> _headers(String token)=>{'Content-Type':'application/json','Authorization':'Bearer $token'};

 static Future<Map<String,dynamic>> login(String phone,String password) async{
   final r=await http.post(Uri.parse('$base/auth/login'),headers:{'Content-Type':'application/json'},
     body:jsonEncode({'phone':phone,'password':password}));
   return jsonDecode(r.body);
 }

 static Future<Map<String,dynamic>> monthly(String token,String month) async{
   final r=await http.get(Uri.parse('$base/reports/monthly?month=$month'),headers:_headers(token));
   return jsonDecode(r.body);
 }

 static Future<Map<String,dynamic>> trucks(String token) async{
   final r=await http.get(Uri.parse('$base/trucks'),headers:_headers(token));
   return jsonDecode(r.body);
 }

 static Future<Map<String,dynamic>> createTruck(String token,String number,String model,String capacity) async{
   final r=await http.post(Uri.parse('$base/trucks'),headers:_headers(token),
     body:jsonEncode({'number':number,'model':model,'capacity':capacity}));
   return jsonDecode(r.body);
 }

 static Future<Map<String,dynamic>> drivers(String token) async{
   final r=await http.get(Uri.parse('$base/drivers'),headers:_headers(token));
   return jsonDecode(r.body);
 }

 static Future<Map<String,dynamic>> createDriver(String token,String name,String phone,String password) async{
   final r=await http.post(Uri.parse('$base/drivers'),headers:_headers(token),
     body:jsonEncode({'name':name,'phone':phone,'password':password}));
   return jsonDecode(r.body);
 }

 static Future<Map<String,dynamic>> trips(String token) async{
   final r=await http.get(Uri.parse('$base/trips'),headers:_headers(token));
   return jsonDecode(r.body);
 }

 static Future<Map<String,dynamic>> createTrip(String token,Map<String,dynamic> body) async{
   final r=await http.post(Uri.parse('$base/trips'),headers:_headers(token),body:jsonEncode(body));
   return jsonDecode(r.body);
 }

 static Future<Map<String,dynamic>> expenses(String token) async{
   final r=await http.get(Uri.parse('$base/expenses'),headers:_headers(token));
   return jsonDecode(r.body);
 }

 static Future<Map<String,dynamic>> createExpense(String token,Map<String,dynamic> body) async{
   final r=await http.post(Uri.parse('$base/expenses'),headers:_headers(token),body:jsonEncode(body));
   return jsonDecode(r.body);
 }

 static Future<Map<String,dynamic>> approveExpense(String token,int id) async{
   final r=await http.post(Uri.parse('$base/expenses/$id/approve'),headers:_headers(token));
   return jsonDecode(r.body);
 }

 static Future<Map<String,dynamic>> rejectExpense(String token,int id,String reason) async{
   final r=await http.post(Uri.parse('$base/expenses/$id/reject'),headers:_headers(token),body:jsonEncode({'reason':reason}));
   return jsonDecode(r.body);
 }

 static Future<Map<String,dynamic>> uploadReceipt(String token,int expenseId,String filePath) async{
   final req=http.MultipartRequest('POST',Uri.parse('$base/expenses/$expenseId/receipt'))
     ..headers['Authorization']='Bearer $token'
     ..files.add(await http.MultipartFile.fromPath('receipt',filePath));
   final streamed=await req.send();
   final body=await streamed.stream.bytesToString();
   return jsonDecode(body);
 }
}
