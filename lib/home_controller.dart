import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';

class HomeController extends GetxController {
  final _credentialFile = "assets/an7or-diary-a33fc732b973.json";
  final _spreadsheetId = '1AP2OJyhpY7zQVr3h46k5Zq1GUXOcUuOSPTaeOpfNaQY';
  final _googleSheetLink = "https://docs.google.com/spreadsheets/d/1AP2OJyhpY7zQVr3h46k5Zq1GUXOcUuOSPTaeOpfNaQY/edit";
  SpreadsheetsResource? spreadsheets;

  final _months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  final _waktos = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha", "Jumu'ah", "Sunrise", "Sunset", "Sahari", "Iftar"];

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

          if (selectedDistrict.value != "Dhaka" && timeInt > 0) {
            int hh = timeInt ~/ 100;
            int mm = timeInt % 100;
            DateTime time = DateTime(DateTime.now().year, 1, 1, hh, mm);
            time = time.add(Duration(minutes: _adjust[i]));
            timeInt = time.hour * 100 + time.minute;
          }

          if (_timeTable[month] == null) {
            _timeTable[month] = {};
          }
          if (_timeTable[month]?[_waktos[i]] == null) {
            _timeTable[month]?[_waktos[i]] = [];
          }

          _timeTable[month]![_waktos[i]]!.add(timeInt);
          i++;
        }
      }
    }
  }

  void _generateAndDownloadBinFile() {
    final offset = 500;
    final totalSize = offset + (12 * 31 * 10 * 2);
    final byteData = ByteData(totalSize);

    for (var i = 0; i < offset; i++) {
      byteData.setUint8(i, 0);
    }

    var writeIndex = offset;
    for (var month in _months) {
      for (var wakto in _waktos) {
        final waqtList = _timeTable[month]![wakto]!;
        for (var waqt in waqtList) {
          byteData.setInt16(writeIndex, waqt, Endian.big);
          writeIndex += 2;
        }
      }
    }

    final bytes = byteData.buffer.asUint8List();
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..target = 'blank'
      ..download = 'PP_TIME_${DateTime.now().year}.bin'
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  void openGoogleSheet() {
    html.window.open(_googleSheetLink, '_blank');
  }

  Future<void> generatePrayerTimes() async {
    if (isLoading.value) {
      Get.showSnackbar(GetSnackBar(
        title: "Error",
        message: "Already in progress...",
        icon: Icon(Icons.error, color: Colors.white),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 2),
      ));
      return;
    }

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

    statusMsg.value = 'Creating bin file...';
    _generateAndDownloadBinFile();

    statusMsg.value = 'Completed.';
    isLoading.value = false;
    Timer(Duration(seconds: 2), () => statusMsg.value = '');
  }
}
