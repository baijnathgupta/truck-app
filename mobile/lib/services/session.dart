import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
class Session {
 static Future<void> save(String token, Map user) async {
   final prefs = await SharedPreferences.getInstance();
   await prefs.setString('token', token);
   await prefs.setString('user', jsonEncode(user));
 }
 static Future<Map<String, dynamic>?> load() async {
   final prefs = await SharedPreferences.getInstance();
   final token = prefs.getString('token');
   final userJson = prefs.getString('user');
   if (token == null || userJson == null) return null;
   return {'token': token, 'user': jsonDecode(userJson)};
 }
 static Future<void> clear() async {
   final prefs = await SharedPreferences.getInstance();
   await prefs.remove('token');
   await prefs.remove('user');
 }
}
