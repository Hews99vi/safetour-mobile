class SosResponse {
  const SosResponse({
    required this.sosId,
    required this.status,
    required this.message,
  });

  final String sosId;
  final String status;
  final String message;

  factory SosResponse.fromJson(Map<String, dynamic> json) {
    return SosResponse(
      sosId: (json['sosId'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
    );
  }
}
