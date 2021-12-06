import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';

class ServiceConfig {
  final String baseUrl = 'https://krista-staging.trackingworks.io';

  Future<dynamic> login(String email, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // String? imei = '-';
    // final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    // try {
    //   if (Platform.isAndroid) {
    //     var build = await deviceInfoPlugin.androidInfo;
    //     imei = build.androidId; //UUID for Android
    //   } else if (Platform.isIOS) {
    //     var data = await deviceInfoPlugin.iosInfo;
    //     imei = data.identifierForVendor; //UUID for iOS
    //   }
    // } on PlatformException {
    //   print('Failed to get platform version');
    // }\

    await prefs.setString('uuid', '97a95688f6ad1ab4');

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String uuid = prefs.getString('uuid') ?? '-';
      Map<String, String> headers = {'user-device': uuid};
      Map<String, String> body = {'email': email, 'password': password};

      print(uuid);
      http.Response res = await http.post(
        Uri.parse('$baseUrl/api/v1/employee/authentication/login'),
        headers: headers,
        body: body,
      );
      return res;
    } catch (e) {
      return e.toString();
    }
  }

  Future<dynamic> getSchedule(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token')!;
    String uuid = prefs.getString('uuid') ?? '-';

    try {
      Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        'user-device': uuid
      };
      DateFormat formatter = DateFormat('yyyy-MM-dd');
      String date = formatter.format(DateTime.now());

      http.Response res = await http.get(
        Uri.parse('$baseUrl/api/v1/employee/schedule?$date'),
        headers: headers,
      );

      if (res.statusCode != 200) {
        var response = jsonDecode(res.body);
        final snackBar = buildSnackbar(response['meta']['error']);
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
      return res;
    } catch (e) {
      final snackBar = buildSnackbar(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return e.toString();
    }
  }

  Future<dynamic> postAttendance(BuildContext context) async {
    await [
      Permission.location,
    ].request();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token')!;
    String uuid = prefs.getString('uuid') ?? '-';

    try {
      var res = await uploadImage(context);
      var responseImage = jsonDecode(res);
      String imageId = responseImage['data']['id'].toString();

        Map<String, String> headers = {
          'Authorization': 'Bearer $token',
          'user-device': uuid
        };

      DateFormat formatter = DateFormat('yyyy-MM-dd');
      DateFormat clockFormatter = DateFormat('HH:mm:ss');
      String date = formatter.format(DateTime.now());
      String clock = clockFormatter.format(DateTime.now());

      Position position = await Geolocator.getCurrentPosition();
      double latitude = position.latitude;
      double longitude = position.longitude;

      String address = '-';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude, localeIdentifier: "id");
        Placemark place = placemarks[0];
        address = place.street ?? '-';
      } catch (e) {
        // we make the address dummy because we can't rely on geocoding plugin
        address = '-';
      }

      print('address $address');

      Map<String, dynamic> body = {
        'date': date.toString(),
        'clock': clock.toString(),
        'type': 'normal',
        'notes': '-',
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'image_id': imageId.toString(),
        'address': address,
      };


      http.Response resData = await http.post(
          Uri.parse('$baseUrl/api/v1/employee/attendance-clock'),
          headers: headers,
          body: body
        );

        if (resData.statusCode != 200) {
          print(resData.body.toString());
          print(date);
          var response = jsonDecode(resData.body);
          print(response['meta']);
          final snackBar = buildSnackbar(response['meta']['message']);
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
        return resData;
    } catch (e) {
      print('error upload image 2');
      final snackBar = buildSnackbar(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return e.toString();
    }
  }

  Future<dynamic> uploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile =
    await picker.pickImage(source: ImageSource.gallery, maxHeight: 200);
    File file = File(pickedFile!.path);

    try {
      var res = await uploadImageHTTP(file, '$baseUrl/api/v1/employee/attendance-image');
      return res;
    } catch (e) {
      print('error upload image');
      final snackBar = buildSnackbar(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return e.toString();
    }
  }

  Future<String?> uploadImageHTTP(file, url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token')!;
    String uuid = prefs.getString('uuid') ?? '-';

    Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      'user-device': uuid
    };

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath('image', file.path));
    var response = await request.send();
    var responseData = await response.stream.toBytes();
    var responseString = String.fromCharCodes(responseData);
    return responseString;
  }

  SnackBar buildSnackbar(String text) {
    return SnackBar(
      content: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.red,
    );
  }
}
