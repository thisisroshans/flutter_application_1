import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exceptions.dart';
import '../../features/todos/data/models/todo.dart';

class ApiClient {
  final http.Client _client;
  final String _baseUrl = 'https://jsonplaceholder.typicode.com';

  final Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36',
  };

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Todo>> getTodos() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/todos'),
      headers: {
        'Accept': 'application/json',
        'User-Agent': _headers['User-Agent']!
      },
    );
    _handleStatusCode(response);
    final List<dynamic> decodedJson = json.decode(response.body);
    return decodedJson.map((json) => Todo.fromJson(json)).toList();
  }

  Future<Todo> createTodo(Todo todo) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/todos'),
      headers: _headers,
      body: json.encode(todo.toJson()),
    );
    _handleStatusCode(response);
    return Todo.fromJson(json.decode(response.body));
  }

  Future<Todo> updateTodo(int id, bool completed) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/todos/$id'),
      headers: _headers,
      body: json.encode({'completed': completed}),
    );
    _handleStatusCode(response);
    return Todo.fromJson(json.decode(response.body));
  }

  Future<void> deleteTodo(int id) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/todos/$id'),
      headers: _headers,
    );
    _handleStatusCode(response);
  }

  void _handleStatusCode(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        break;
      case 400:
        throw BadRequestException(response.body.toString());
      case 401:
      case 403:
        throw UnauthorisedException(
            "Access Denied by Server. Check headers or API limits.");
      case 404:
        throw FetchDataException('Not Found: ${response.request?.url}');
      case 500:
      default:
        throw FetchDataException(
          'Error occurred while communicating with server with StatusCode : ${response.statusCode}',
        );
    }
  }
}
