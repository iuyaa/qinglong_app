import 'package:json_conversion_annotation/json_conversion_annotation.dart';

@JsonConversion()
class SystemBean {
  String? version;
  bool? fromAutoGet = true;

  SystemBean({
    this.version,
    this.fromAutoGet,
  });

  SystemBean.fromJson(Map<String, dynamic> json) {
    version = json['version'];
  }

  bool isAtLeast(int major, int minor, int patch) {
    final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(?:[-+][0-9A-Za-z.-]+)?$')
        .firstMatch(version?.trim() ?? '');
    if (match == null) return false;
    final target = [major, minor, patch];
    for (var i = 0; i < 3; i++) {
      final part = int.tryParse(match.group(i + 1)!);
      if (part == null) return false;
      if (part != target[i]) return part > target[i];
    }
    return true;
  }

  bool isUpperVersion2_13_9() => isAtLeast(2, 13, 9);
  bool isUpperVersion2_12_2() => isAtLeast(2, 12, 2);
  bool isUpperVersion2_14_5() => isAtLeast(2, 14, 5);
  bool isUpperVersion2_13_0() => isAtLeast(2, 13, 0);
  bool isUpperVersion2_14_0() => isAtLeast(2, 14, 0);
  bool isUpperVersion() => isAtLeast(2, 10, 14);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['version'] = this.version;
    return data;
  }

  static SystemBean jsonConversion(Map<String, dynamic> json) {
    return SystemBean.fromJson(json);
  }
}

