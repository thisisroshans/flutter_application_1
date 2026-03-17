import 'dart:math';

import '../../../../core/local_storage/local_storage_service.dart';

class AuthRepository {
  AuthRepository({required this.storageService});
  final LocalStorageService storageService;

  Future<bool> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final areCredentialsValid = username == 'admin' && password == 'password';

    if (areCredentialsValid) {
      final token = _generateToken();
      await storageService.saveToken(token);
    }

    return areCredentialsValid;
  }

  Future<void> logout() async {
    await storageService.deleteToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await storageService.getToken();
    return token != null;
  }

  String _generateToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return values.join();
  }
}
