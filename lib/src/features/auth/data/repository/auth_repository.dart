class AuthRepository {
  Future<bool> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    return username == 'admin' && password == 'password';
  }
}
