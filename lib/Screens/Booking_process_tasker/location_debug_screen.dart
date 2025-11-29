// lib/screens/location_debug_screen.dart
import 'package:flutter/material.dart';
// lib/screens/location_signalr_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:taskoon/Models/location_update.dart';
import 'package:taskoon/Service/location_api_service.dart';
import 'package:taskoon/Service/location_hub_service.dart';

// lib/screens/location_signalr_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';


class LocationSignalRScreen extends StatefulWidget {
  const LocationSignalRScreen({super.key});

  @override
  State<LocationSignalRScreen> createState() => _LocationSignalRScreenState();
}

class _LocationSignalRScreenState extends State<LocationSignalRScreen> {
  // TODO: change to your real IP/host
  static const String _baseUrl = 'http://192.3.3.187:85';

  late final AddressApiService _api;
  late final LocationHubService _hub;

  final _userIdCtrl = TextEditingController(
    text: '46C79690-6B69-459E-8D01-06043D4190AC', // example
  );
  final _latCtrl = TextEditingController(text: '24.435');
  final _lngCtrl = TextEditingController(text: '67.435');

  String _status = 'Disconnected';
  AddressLocation? _lastSignalRUpdate;
  AddressLocation? _lastApiResult;
  StreamSubscription<AddressLocation>? _sub;

  bool _sending = false;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _api = AddressApiService(baseUrl: _baseUrl);
    _hub = LocationHubService(hubUrl: '$_baseUrl/hubs/location');
  }

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _sub?.cancel();
    _hub.stop();
    _hub.dispose();
    super.dispose();
  }

  Future<void> _connectHub() async {
    if (_connecting) return;

    setState(() {
      _connecting = true;
      _status = 'Connecting...';
    });

    try {
      await _hub.start();
      _status = _hub.isConnected ? 'Connected' : 'Disconnected';

      _sub ??= _hub.locationStream.listen((loc) {
        setState(() {
          _lastSignalRUpdate = loc;
        });
      });
    } catch (e) {
      _status = 'Error: $e';
    } finally {
      setState(() {
        _connecting = false;
      });
    }
  }

  Future<void> _disconnectHub() async {
    await _hub.stop();
    await _sub?.cancel();
    _sub = null;

    setState(() {
      _status = 'Disconnected';
    });
  }

  Future<void> _sendLocation() async {
    if (_sending) return;

    final userId = _userIdCtrl.text.trim();
    if (userId.isEmpty) return;

    final double? lat = double.tryParse(_latCtrl.text.trim());
    final double? lng = double.tryParse(_lngCtrl.text.trim());

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid latitude & longitude')),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      final loc = await _api.updateLocation(
        userId: userId,
        latitude: lat,
        longitude: lng,
      );

      setState(() {
        _lastApiResult = loc;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location updated via API')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API error: $e')),
      );
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const kPrimary = Color(0xFF5C2E91);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location SignalR Demo'),
        backgroundColor: kPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'REST API:  $_baseUrl/api/Address/update/location',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Hub:       $_baseUrl/hubs/location',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Inputs
            TextField(
              controller: _userIdCtrl,
              decoration: const InputDecoration(
                labelText: 'User ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lngCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sending ? null : _sendLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                    ),
                    child: _sending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Send via API'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _hub.isConnected ? null : _connectHub,
                    child: _connecting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Connect Hub'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _hub.isConnected ? _disconnectHub : null,
                    child: const Text('Disconnect'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Hub status: $_status',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 32),

            const Text(
              'Last API Response (result):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (_lastApiResult == null)
              const Text('None yet')
            else
              _LocationTile(loc: _lastApiResult!, color: Colors.blueGrey),

            const SizedBox(height: 20),

            const Text(
              'Last SignalR "LocationUpdated":',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (_lastSignalRUpdate == null)
              const Text('No updates received yet')
            else
              _LocationTile(loc: _lastSignalRUpdate!, color: Colors.green),
          ],
        ),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({required this.loc, required this.color});

  final AddressLocation loc;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.06),
      child: ListTile(
        title: Text('User: ${loc.userId}'),
        subtitle: Text(
          'Lat: ${loc.latitude}, Lng: ${loc.longitude}\n'
          'City: ${loc.city ?? '-'} | Country: ${loc.country ?? '-'}',
        ),
      ),
    );
  }
}
