import 'package:flutter/material.dart';
import 'package:masjid_app/core/constants/app_colors.dart';

class IqamaScreen extends StatelessWidget {
  final String prayerName;
  const IqamaScreen({super.key, required this.prayerName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage("assets/images/BG.png"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.65),
              BlendMode.darken,
            ),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📵', style: TextStyle(fontSize: 90)),
            SizedBox(height: 0),
            Text(
              'يُرجى وضع الهاتف على الصامت',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1,
                fontSize: 50,
                color: defaultGoldTextColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
            SizedBox(height: 5),
            Text(
              'النظر موضع السجود في الصلاة',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1,
                fontSize: 50,
                color: defaultGoldTextColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
