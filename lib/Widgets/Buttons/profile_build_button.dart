import 'package:eat_wise/main.dart';
import 'package:flutter/material.dart';

class ProfileBuildButton extends StatelessWidget {
  final text;
  final void Function()? ontap;
  const ProfileBuildButton({super.key, this.text, this.ontap});

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: ontap,
      child: Container(
        height: mq.height * 0.05,
        width: mq.width * 0.15,
        decoration: BoxDecoration(
            color: Colors.green, borderRadius: BorderRadius.circular(50)),
        child: const Center(child: Icon(Icons.add)),
      ),
    );
  }
}
