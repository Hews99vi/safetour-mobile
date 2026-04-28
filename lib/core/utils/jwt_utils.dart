import 'dart:convert';

class JwtPayload {
  const JwtPayload({required this.userId, required this.role});

  final String userId;
  final String role;
}

JwtPayload? decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;

  try {
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final json = jsonDecode(payload);
    if (json is! Map<String, dynamic>) return null;

    final userId = json['userId']?.toString();
    final role = json['role']?.toString();
    if (userId == null || userId.isEmpty || role == null || role.isEmpty) {
      return null;
    }

    return JwtPayload(userId: userId, role: role);
  } catch (_) {
    return null;
  }
}
