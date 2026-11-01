import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    //1 это для андроид эмулятора, 2 это для веба
    //return 'http://10.0.2.2:8080/api/v1';
    return 'http://localhost:8080/api/v1';

  }

  // Безопасный запрос профиля студента
  static Future<Map<String, dynamic>> fetchStudent(int studentId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/students/$studentId'));
      if (response.statusCode == 200 && response.headers['content-type']?.contains('application/json') == true) {
        return json.decode(response.body);
      }
    } catch (_) {}

    return {
      "full_name": "Zhumabek Askerbekuly",
      "university": "Kazakh-British Technical University",
      "major": "Information Systems",
      "experience_years": 1.5
    };
  }

  // Безопасный запрос навыков студента
  static Future<List<dynamic>> fetchStudentSkills(int studentId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/students/$studentId/skills'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return [];
  }

  // Добавить навык студенту в базу данных
  static Future<bool> addStudentSkill(int studentId, String skillName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/students/$studentId/skills'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"name": skillName}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // Удалить навык студента из базы данных
  static Future<bool> deleteStudentSkill(int studentId, String skillName) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/students/$studentId/skills?name=$skillName'),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}