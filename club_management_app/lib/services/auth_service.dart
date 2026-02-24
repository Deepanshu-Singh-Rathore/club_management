class AuthService {
  static Future login(String email, String password, String role) async {
    print("Login -> $email, $password, $role");
    // Backend API call future me yaha add karenge
  }

  static Future signup(String email, String password, String role) async {
    print("Signup -> $email, $password, $role");
  }

  static Future verifyOtp(String email, String otp) async {
    print("Verify OTP -> $email, $otp");
  }
}
