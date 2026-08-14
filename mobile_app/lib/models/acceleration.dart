/// MPU6050 sensöründen gelen X, Y ve Z eksenlerindeki ivme verilerini temsil eder.
library;

class Acceleration {
  final int x;
  final int y;
  final int z;

  Acceleration({required this.x, required this.y, required this.z});

  factory Acceleration.fromJson(Map<String, dynamic> json) {
    return Acceleration(x: json["x"], y: json["y"], z: json["z"]);
  }

  Map<String, dynamic> toJson() {
    return {"x": x, "y": y, "z": z};
  }
}
