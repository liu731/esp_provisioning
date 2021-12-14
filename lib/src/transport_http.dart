import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'transport.dart';
import 'package:string_validator/string_validator.dart';

class TransportHTTP implements Transport {
  late String _hostname;
  final Duration _timeout = const Duration(seconds: 30);
  Map<String, String> _headers = {};
  final _client = http.Client();

  TransportHTTP(String hostname) {
    if (!isURL(hostname)) {
      throw const FormatException('hostname should be an URL.');
    } else {
      _hostname = hostname;
    }
    _headers["Content-type"] = "application/x-www-form-urlencoded";
    _headers["Accept"] = "text/plain";
  }

  @override
  Future<bool> connect() async {
    return true;
  }

  @override
  Future<void> disconnect() async {
    _client.close();
  }

  void _updateCookie(http.Response response) {
    if (null != response.headers['set-cookie']) {
      String rawCookie = response.headers['set-cookie']!;
      int index = rawCookie.indexOf(';');
      _headers['cookie'] =
          (index == -1) ? rawCookie : rawCookie.substring(0, index);
    }
  }

  @override
  Future<Uint8List> sendReceive(String epName, Uint8List data) async {
    try {
      print("Connecting to " + _hostname + "/" + epName);
      final response = await _client
          .post(
              Uri.http(
                _hostname,
                "/" + epName,
              ),
              headers: _headers,
              body: data)
          .timeout(_timeout)
          .catchError((error) {
        print(error);
      });

      _updateCookie(response);
      if (response.statusCode == 200) {
        print('Connection successful');
        //client.close();
        final Uint8List bodyBytes = response.bodyBytes;
        return bodyBytes;
      } else {
        print('Connection failed');
        throw Exception("ESP Device doesn't repond");
      }
    } catch (e) {
      throw StateError('Connection error ' + e.toString());
    }
  }
}
