import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pptime_generator/home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final homeCtx = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SizedBox(
          height: 256,
          width: 500,
          child: Card(
            color: Colors.white,
            clipBehavior: Clip.hardEdge,
            elevation: 35,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    spacing: 20,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          "Permanent Prayer Time",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text("24CXX EEPROM .bin file generator"),
                        trailing: Image.asset("assets/ic.png"),
                      ),
                      Obx(
                        () => DropdownButtonFormField<String>(
                          menuMaxHeight: 250,
                          decoration: InputDecoration(
                            labelText: "Select District",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: homeCtx.districts
                              .map((district) => DropdownMenuItem<String>(
                                    value: district,
                                    child: Text(district),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            homeCtx.selectedDistrict.value = value ?? homeCtx.districts[0];
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            homeCtx.generatePrayerTimes();
                          },
                          style: ButtonStyle(
                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 20, horizontal: 25)),
                            backgroundColor: WidgetStatePropertyAll(Colors.blueAccent),
                            foregroundColor: WidgetStatePropertyAll(Colors.white),
                          ),
                          child: Text("Generate"),
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(
                  () => homeCtx.isLoading.value ? LinearProgressIndicator() : SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
