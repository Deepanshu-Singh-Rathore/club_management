import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/club.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000/api";

  static Future<List<Club>> fetchClubs() async {
    final response = await http.get(Uri.parse('$baseUrl/clubs/'));

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((club) => Club.fromJson(club)).toList();
    } else {
      print(response.body);
      throw Exception('Failed: ${response.statusCode}');
    }
  }
}
