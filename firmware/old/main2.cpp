#include <Arduino.h>
#include <Wire.h>
#include <DHT.h>

#define MPU_ADDR 0x68

// ---- DHT22 (modül: + OUT -) ----
#define DHTPIN 4        // OUT hangi GPIO'ya bağlıysa onu yaz
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

// ---- I2C pins (ESP32 default) ----
static const int SDA_PIN = 21; // D21
static const int SCL_PIN = 22; // D22

void mpuWrite(uint8_t reg, uint8_t val) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  Wire.write(val);
  Wire.endTransmission();
}

bool mpuReadBytes(uint8_t reg, uint8_t* buf, size_t len) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  if (Wire.endTransmission(false) != 0) return false; // repeated start

  uint8_t got = Wire.requestFrom(MPU_ADDR, (uint8_t)len);
  if (got != len) return false;

  for (size_t i = 0; i < len; i++) {
    buf[i] = Wire.read();
  }
  return true;
}

int16_t be16(const uint8_t* b) {
  return (int16_t)((b[0] << 8) | b[1]);
}

void setup() {
  Serial.begin(115200);

  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setClock(100000); // 100kHz daha stabil
  delay(300);

  // MPU6050 wake up (PWR_MGMT_1)
  mpuWrite(0x6B, 0x00);
  delay(100);

  dht.begin();
  delay(1500); // DHT ilk okuma için

  Serial.println("{\"status\":\"boot_ok\"}");
}

void loop() {
  // ---- MPU6050: Accel+Gyro (14 byte burst) ----
  // 0x3B: ACCEL_XOUT_H ... TEMP ... GYRO_ZOUT_L
  uint8_t b[14];
  bool mpuOk = mpuReadBytes(0x3B, b, sizeof(b));

  int16_t ax=0, ay=0, az=0, gx=0, gy=0, gz=0;
  if (mpuOk) {
    ax = be16(&b[0]);
    ay = be16(&b[2]);
    az = be16(&b[4]);
    // temp is b[6],b[7] (istersen kullanırız)
    gx = be16(&b[8]);
    gy = be16(&b[10]);
    gz = be16(&b[12]);
  }

  // ---- DHT22 ----
  float temp = dht.readTemperature();
  float hum  = dht.readHumidity();
  bool tempOk = !isnan(temp);
  bool humOk  = !isnan(hum);

  // ---- JSON (tek satır) ----
  Serial.print("{\"mpu_ok\":");
  Serial.print(mpuOk ? "true" : "false");

  Serial.print(",\"ax\":"); Serial.print(ax);
  Serial.print(",\"ay\":"); Serial.print(ay);
  Serial.print(",\"az\":"); Serial.print(az);

  Serial.print(",\"gx\":"); Serial.print(gx);
  Serial.print(",\"gy\":"); Serial.print(gy);
  Serial.print(",\"gz\":"); Serial.print(gz);

  Serial.print(",\"temp\":");
  if (tempOk) Serial.print(temp, 2); else Serial.print("null");

  Serial.print(",\"hum\":");
  if (humOk) Serial.print(hum, 2); else Serial.print("null");

  Serial.println("}");

  delay(500); // MPU hızlı olabilir ama başlangıç için yeterli
}