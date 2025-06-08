import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastService {
  static void showSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.deepPurple.shade400,
      textColor: Colors.white,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      webPosition: "center",
    );
  }

  static void showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      timeInSecForIosWeb: 3,
      gravity: ToastGravity.BOTTOM,
      webPosition: "center",
    );
  }
}
