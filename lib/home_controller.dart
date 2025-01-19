import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';

class HomeController extends GetxController {
  final _credentialFile = "assets/an7or-diary-a33fc732b973.json";
  final _spreadsheetId = '1AP2OJyhpY7zQVr3h46k5Zq1GUXOcUuOSPTaeOpfNaQY';
  SpreadsheetsResource? spreadsheets;

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
    await testRead();
  }

  Future<void> testRead() async {
    if (spreadsheets == null) return;
    final data = await spreadsheets!.values.get(_spreadsheetId, "Adjust!A:K");
    if (data.values != null) {
      print('Data from the Google Sheet: ');
      for (var row in data.values!) {
        print(row);
      }
    }
  }
}
