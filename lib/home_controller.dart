import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';

class HomeController extends GetxController {
  final _credentialFile = "assets/an7or-diary-a33fc732b973.json";
  final _spreadsheetId = '1AP2OJyhpY7zQVr3h46k5Zq1GUXOcUuOSPTaeOpfNaQY';
  SpreadsheetsResource? spreadsheets;

  final _months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  final _waktos = ["Sahari", "Fajr", "Dhuhr", "Asr", "Maghrib", "Isha", "Jumu'ah", "Sunrise", "Sunset", "Iftar"];

  // state
  var districts = <String>[].obs;
  var selectedDistrict = ''.obs;
  var isLoading = false.obs;
  var statusMsg = ''.obs;

  // variables
  final List<int> _adjust = [];
  final Map<String, Map<String, List<int>>> _timeTable = {};

  Future<void> _initGoogleSheet() async {
    String jsonFile = await rootBundle.loadString(_credentialFile);
    final serviceAccountCredentials = ServiceAccountCredentials.fromJson(json.decode(jsonFile));
    const scopes = [SheetsApi.spreadsheetsReadonlyScope];

    final authClient = await clientViaServiceAccount(serviceAccountCredentials, scopes);
    final sheetsApi = SheetsApi(authClient);

    spreadsheets = sheetsApi.spreadsheets;
  }

  Future<void> getDistricts() async {
    await _initGoogleSheet();

    final data = await spreadsheets!.values.get(_spreadsheetId, "Adjust!A1:A");
    if (data.values != null) {
      districts.clear();
      for (var row in data.values!) {
        final district = row.first as String;
        districts.add(district);
      }
      districts.removeAt(0);
      districts.insert(0, "Dhaka");
    }
  }

  Future<void> _getAdjustRow() async {
    final data = await spreadsheets!.values.get(_spreadsheetId, "Adjust!A:K");
    if (data.values != null) {
      _adjust.clear();
      for (List<dynamic> row in data.values!) {
        if (row.first == selectedDistrict.value) {
          _adjust.addAll(row.sublist(1).map((cell) => int.tryParse(cell) ?? 0));
          break;
        }
      }
    }
  }

  Future<void> _getTimeTableByMonth(String month) async {
    final data = await spreadsheets!.values.get(_spreadsheetId, "$month!B2:K");
    if (data.values != null) {
      _timeTable[month]?.clear();

      for (int k = 0; k < 31; k++) {
        final row = k < data.values!.length ? data.values![k] : List.filled(10, "0");
        int i = 0;
        for (String timeStr in row as List<dynamic>) {
          int timeInt = int.tryParse(timeStr) ?? 0;

          if (selectedDistrict.value != "Dhaka") {
            int hh = timeInt ~/ 100;
            int mm = timeInt % 100;
            DateTime time = DateTime(2000, 1, 1, hh, mm);
            time = time.add(Duration(minutes: _adjust[i]));
            timeInt = time.hour * 100 + time.minute;
          }

          if (_timeTable[month] == null) {
            _timeTable[month] = {};
          }
          if (_timeTable[month]?[_waktos[i]] == null) {
            _timeTable[month]?[_waktos[i]] = [];
          }

          _timeTable[month]?[_waktos[i]]?.add(timeInt);
          i++;
        }
      }
    }
  }

  Future<void> generatePrayerTimes() async {
    isLoading.value = true;

    statusMsg.value = 'Checking district...';
    if (selectedDistrict.isEmpty) {
      Get.showSnackbar(GetSnackBar(
        title: "Error",
        message: "Please select district!",
        icon: Icon(Icons.error, color: Colors.white),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 2),
      ));

      statusMsg.value = 'Failed!';
      isLoading.value = false;
      Timer(Duration(seconds: 2), () => statusMsg.value = '');
      return;
    }

    if (selectedDistrict.value != "Dhaka") {
      statusMsg.value = 'Getting adjust data...';
      await _getAdjustRow();
    }

    for (var month in _months) {
      statusMsg.value = 'Getting $month data...';
      await _getTimeTableByMonth(month);
    }

    statusMsg.value = 'Completed.';
    isLoading.value = false;
    Timer(Duration(seconds: 2), () => statusMsg.value = '');
  }
}
