class AuthService {
  // For now, store a fake user for demonstration
  static const String _validEmail = 'test@gmail.com';
  static const String _validPassword = '123456';
  static const String _validOtp = '000000';

  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return email == _validEmail && password == _validPassword;
  }

  Future<bool> signup(String email, String password) async {
    // dummy always succeeds
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  Future<bool> verifyOtp(String otp) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return otp == _validOtp;
  }
}
