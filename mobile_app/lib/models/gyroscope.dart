/// ------------------------------------------------------------
/// Gyroscope Model
/// ------------------------------------------------------------
///
/// MPU6050 sensöründen gelen
/// açısal hız (X, Y, Z) verilerini temsil eder.
///
/// ------------------------------------------------------------
library;

class Gyroscope {
  final int x;
  final int y;
  final int z;

  Gyroscope({required this.x, required this.y, required this.z});

  factory Gyroscope.fromJson(Map<String, dynamic> json) {
    return Gyroscope(x: json["x"], y: json["y"], z: json["z"]);
  }

  Map<String, dynamic> toJson() {
    return {"x": x, "y": y, "z": z};
  }
}
