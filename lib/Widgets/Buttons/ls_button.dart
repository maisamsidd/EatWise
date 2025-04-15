import 'package:eat_wise/main.dart';
import 'package:flutter/material.dart';

class LsButton extends StatelessWidget {
  final text;
  final void Function()? ontap;
  const LsButton({super.key, this.text, this.ontap});

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: ontap,
      child: Container(
        height: mq.height * 0.055,
        width: mq.width * 0.8,
        decoration: BoxDecoration(
            color: Colors.blue, borderRadius: BorderRadius.circular(15)),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
