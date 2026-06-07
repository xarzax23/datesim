import 'package:firebase_auth/firebase_auth.dart';

import 'config.dart';

Future<Map<String, String>> authHeaders(FirebaseAuth auth) async {
  if (localAuthEnabled) {
    return {'Authorization': 'Bearer $localAuthToken'};
  }

  final token = await auth.currentUser?.getIdToken();
  return {if (token != null) 'Authorization': 'Bearer $token'};
}
