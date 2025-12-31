import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taskoon/Models/location_update.dart';



class AddressApiService {
  final String baseUrl; // e.g. http://192.3.3.187:85
  final http.Client _client;

  AddressApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<AddressLocation> updateLocation({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('$baseUrl/api/Address/update/location');

    final body = jsonEncode({
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
    });

    final res = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'accept': 'text/plain',
      },
      body: body,
    );

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final Map<String, dynamic> json = jsonDecode(res.body);
    final apiRes = AddressUpdateResponse.fromJson(json);

    if (!apiRes.isSuccess || apiRes.result == null) {
      throw Exception(
        apiRes.message.isEmpty ? 'Address update failed' : apiRes.message,
      );
    }

    return apiRes.result!;
  }
}
