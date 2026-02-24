class StartSosResult {
  final String sosId;

  StartSosResult({required this.sosId});

  factory StartSosResult.fromJson(Map<String, dynamic> json) {
    return StartSosResult(
      sosId: json['sosId']?.toString() ?? '',
    );
  }
}