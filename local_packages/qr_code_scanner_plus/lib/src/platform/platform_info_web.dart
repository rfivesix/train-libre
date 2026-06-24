import 'package:web/web.dart' as web;

String get osVersion {
  try {
    return "Web ${web.window.navigator.userAgent}";
  } catch (e) {
    return "Web";
  }
}

bool get isIos => false;
