import 'package:flutter/foundation.dart';
import 'package:money_mirror/core/utils/app_config.dart';

void appLog(Object? message) {
  if (kDebugMode && AppConfig.isPrintAllowed) {
    print(message);
  }
}
