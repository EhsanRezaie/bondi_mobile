import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class GoogleAuthService {
  static String get _webClientId => dotenv.env['WEB_CLIENT_ID'] ?? '';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: _webClientId,
  );

  Future<Map<String, String>?> signIn() async {
    try {
      
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account == null) {
        return null;
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      final idToken = auth.idToken;
      if (idToken == null) {
        return null;
      }

      return {
        'id_token': idToken,
        'name': account.displayName ?? '',
        'email': account.email,
        'picture': account.photoUrl ?? '',
      };
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}