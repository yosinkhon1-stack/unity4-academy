import 'package:flutter/material.dart';

Color getCardColor(int score, int absence) {
  if (score <= -15) {
    return Colors.red.shade100;
  } else if (score >= -14 && score <= -10) {
    return Colors.orange.shade100;
  } else if (score >= -9 && score <= 9) {
    return Colors.yellow.shade100;
  } else if (score >= 10 && score <= 14) {
    return Colors.lightGreen.shade100;
  } else if (score >= 15) {
    return Colors.green.shade100;
  } else {
    return Colors.grey.shade100;
  }
}
