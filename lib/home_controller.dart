import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';

class HomeController extends GetxController {
  final _credentialFile = "assets/an7or-diary-a33fc732b973.json";
  final _spreadsheetId = '1AP2OJyhpY7zQVr3h46k5Zq1GUXOcUuOSPTaeOpfNaQY';
  SpreadsheetsResource? spreadsheets;

  // state
  var districts = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    initGoogleSheet();
  }

  Future<void> initGoogleSheet() async {
    String jsonFile = await rootBundle.loadString(_credentialFile);
    final serviceAccountCredentials = ServiceAccountCredentials.fromJson(json.decode(jsonFile));
    const scopes = [SheetsApi.spreadsheetsReadonlyScope];

    final authClient = await clientViaServiceAccount(serviceAccountCredentials, scopes);
    final sheetsApi = SheetsApi(authClient);

    spreadsheets = sheetsApi.spreadsheets;
    await getDistricts();
  }

  Future<void> getDistricts() async {
    if (spreadsheets == null) return;
    final data = await spreadsheets!.values.get(_spreadsheetId, "Adjust!A1:A63");
    if (data.values != null) {
      districts.clear();
      for (var row in data.values!) {
        final district = row.first as String;
        districts.add(district);
      }
      districts.removeAt(0);
    }
  }
}
