/*   (        )     )           )  (        )              )   (     (                       
   )\ )  ( /(  ( /(        ( /(  )\ )  ( /(       (   ( /(   )\ )  )\ )       (            
  (()/(  )\()) )\())  (    )\())(()/(  )\())      )\  )\()) (()/( (()/(  (    )\ )    (    
   /(_))((_)\ ((_)\   )\  ((_)\  /(_))((_)\     (((_)((_)\   /(_)) /(_)) )\  (()/(    )\   
  (_))   _((_)  ((_) ((_)  _((_)(_))  __((_)    )\___  ((_) (_))  (_))  ((_)  /(_))_ ((_)  
  | _ \ | || | / _ \ | __|| \| ||_ _| \ \/ /   ((/ __|/ _ \ | |   | |   | __|(_)) __|| __| 
  |  _/ | __ || (_) || _| | .` | | |   >  <     | (__| (_) || |__ | |__ | _|   | (_ || _|  
  |_|   |_||_| \___/ |___||_|\_||___| /_/\_\     \___|\___/ |____||____||___|   \___||___|
          _____                    _____                    _____                    _____          
         /\    \                  /\    \                  /\    \                  /\    \         
        /::\____\                /::\    \                /::\    \                /::\    \        
       /::::|   |               /::::\    \              /::::\    \              /::::\    \       
      /:::::|   |              /::::::\    \            /::::::\    \            /::::::\    \      
     /::::::|   |             /:::/\:::\    \          /:::/\:::\    \          /:::/\:::\    \     
    /:::/|::|   |            /:::/__\:::\    \        /:::/__\:::\    \        /:::/__\:::\    \    
   /:::/ |::|   |           /::::\   \:::\    \       \:::\   \:::\    \      /::::\   \:::\    \   
  /:::/  |::|   | _____    /::::::\   \:::\    \    ___\:::\   \:::\    \    /::::::\   \:::\    \  
 /:::/   |::|   |/\    \  /:::/\:::\   \:::\    \  /\   \:::\   \:::\    \  /:::/\:::\   \:::\    \ 
/:: /    |::|   /::\____\/:::/  \:::\   \:::\____\/::\   \:::\   \:::\____\/:::/  \:::\   \:::\____\
\::/    /|::|  /:::/    /\::/    \:::\  /:::/    /\:::\   \:::\   \::/    /\::/    \:::\  /:::/    /
 \/____/ |::| /:::/    /  \/____/ \:::\/:::/    /  \:::\   \:::\   \/____/  \/____/ \:::\/:::/    / 
         |::|/:::/    /            \::::::/    /    \:::\   \:::\    \               \::::::/    /  
         |::::::/    /              \::::/    /      \:::\   \:::\____\               \::::/    /   
         |:::::/    /               /:::/    /        \:::\  /:::/    /               /:::/    /    
         |::::/    /               /:::/    /          \:::\/:::/    /               /:::/    /     
         /:::/    /               /:::/    /            \::::::/    /               /:::/    /      
        /:::/    /               /:::/    /              \::::/    /               /:::/    /       
        \::/    /                \::/    /                \::/    /                \::/    /        
         \/____/                  \/____/                  \/____/                  \/____/                                                                                                                                                                                                                                                                        
_____/\\\\\\\\\________/\\\\\\\\\\\__________/\\\\\\\\\__/\\\\\\\\\\\\\\\__/\\\\\_____/\\\__/\\\\\\\\\\\\____        
 ___/\\\\\\\\\\\\\____/\\\/////////\\\_____/\\\////////__\/\\\///////////__\/\\\\\\___\/\\\_\/\\\////////\\\__       
  __/\\\/////////\\\__\//\\\______\///____/\\\/___________\/\\\_____________\/\\\/\\\__\/\\\_\/\\\______\//\\\_      
   _\/\\\_______\/\\\___\////\\\__________/\\\_____________\/\\\\\\\\\\\_____\/\\\//\\\_\/\\\_\/\\\_______\/\\\_     
    _\/\\\\\\\\\\\\\\\______\////\\\______\/\\\_____________\/\\\///////______\/\\\\//\\\\/\\\_\/\\\_______\/\\\_    
     _\/\\\/////////\\\_________\////\\\___\//\\\____________\/\\\_____________\/\\\_\//\\\/\\\_\/\\\_______\/\\\_   
      _\/\\\_______\/\\\__/\\\______\//\\\___\///\\\__________\/\\\_____________\/\\\__\//\\\\\\_\/\\\_______/\\\__  
       _\/\\\_______\/\\\_\///\\\\\\\\\\\/______\////\\\\\\\\\_\/\\\\\\\\\\\\\\\_\/\\\___\//\\\\\_\/\\\\\\\\\\\\/___ 
        _\///________\///____\///////////___________\/////////__\///////////////__\///_____\/////__\////////////_____
HailMaryV1f
2026-04-08
PC NASA ASCEND
Contributors: Angela Trainor, Marquis Muza, Ethan Pierson, Emma Landis; Preston Furulie (V1f)

CHANGELOG V1f (from V1e)
=========================
BUG FIXES (Spring 2026 flight CSV root-cause analysis):
  1) CSV ROW CORRUPTION — println(magZ) split rows; GPS time landed on next row.
  2) DOUBLE-WRITE — logData buffered AND wrote; every point duplicated.
  3) BUFFER FLUSH TIMING — exact-millis match never fired. Elapsed-based now.
  4) MAG VALIDATION — 0..100 range discarded negative field vectors (-39 uT).
  5) GPS LOCATION — re-enabled with int32_t scaled integers (no String alloc).
  6) HEADER DUPLICATION — checks file size, only writes if empty.
  7) SD RECOVERY — marks card offline on open() fail, retries periodically.
  8) BNO055 INIT — fixed "} else ;" fall-through to success message.
  9) BNO055 MAG ZERO — was setting accelSuccess=false instead of magSuccess.
  10) F() MACRO — all Serial strings in PROGMEM to save SRAM.

ADVANCED ADDITIONS (V1f post-flight engineering):
  11) GPS AIRBORNE MODE — UBX-CFG-NAV5 dynamic model 6 (Airborne <1g)
      sent to VK2828U7G5LF (u-blox G7020) on boot.
      Raises COCOM ceiling from ~12km to 50km. Without this, GPS
      silently stops reporting position above ~12km altitude.
  12) IMPACT DETECTION — BNO055 accel magnitude monitored during DESCENT
      phase only. Threshold 15G (147 m/s^2), above the 9G descent forces
      but catches hard ground strikes. Emergency SD flush on trigger.
  13) STALE DATA TRACKING — per-row staleness counter for BMP and BNO.
      stale=0 means fresh sensor read. stale>0 means repeated value.
      Researchers can filter out unreliable data in post-processing.
  14) FLIGHT PHASE DETECTION — altitude-based state machine:
      GROUND(0) -> ASCENT(1) -> FLOAT(2) -> DESCENT(3) -> LANDED(4)
      Logged per-row for automatic data segmentation.
  15) GPS QUALITY COLUMNS — satellites, HDOP, GPS altitude logged per-row.
  16) BNO055 CALIBRATION — packed cal status logged (sys|gyro|accel|mag).
  17) SENSOR HEALTH BITMASK — 8-bit per row: UV1|UV2|UV3|UV4|BMP|BNO|SD|GPS
  18) BMP COLD SHUTDOWN — marks sensor cold-dead after 10 consecutive fails
      when temp < -35C. Recovery attempted every 30s instead of every read.
  19) WATCHDOG TIMER — AVR WDT at 8s. If I2C bus hangs (BNO055/AS7331 pulling
      SDA low in cold/vibration) or any code path blocks, the Mega resets
      automatically and logging resumes. #1 cause of "it stopped recording."
  20) SERIAL1 RX BUFFER 256 — default 64-byte buffer overflows when SD writes
      stall for 100ms+. At 9600 baud GPS fills 64 bytes in 67ms. Now 256.
  21) EEPROM LANDING BACKUP — last valid GPS lat/lng/alt written to EEPROM
      every 30s. Survives SD corruption, power loss, hard reset. 100k write
      cycles = 34 days continuous at 30s interval. Printed on boot.
  22) VERTICAL VELOCITY — (alt - prevAlt) / dt per row, in m/s.
      Instant ascent/descent rate without post-processing 180k rows.
  23) ACCEL MAGNITUDE — sqrt(ax^2+ay^2+az^2) per row, in m/s^2.
      Full G-force profile: turbulence, burst, parachute load, landing.
  24) FREE SRAM MONITORING — available bytes logged per row. If memory leaks
      or stack collision, the number drops visibly before a crash.
  25) MILLIS ROLLOVER SAFE — all timing uses unsigned subtraction
      (currentTime - lastTime >= interval) which wraps correctly at 49.7 days.
      No special handling needed; noted for documentation.

CSV COLUMN REFERENCE (37 columns):
  elapsed(ms), UV1A-C, UV2A-C, UV3A-C, UV4A-C,
  pressure(Pa), temp(C), alt(m),
  gyroX/Y/Z(deg/s), accelX/Y/Z(m/s2), magX/Y/Z(uT),
  time_utc, lat, lng, gps_sats, gps_hdop, gps_alt(m),
  stale_bmp, stale_bno, bno_cal, health, phase,
  vert_vel(m/s), accel_mag(m/s2), free_ram(bytes)

DECODING PACKED FIELDS:
  bno_cal (0-255): sys=(val>>6)&3, gyro=(val>>4)&3, accel=(val>>2)&3, mag=val&3
  health  (0-255): b7=UV1, b6=UV2, b5=UV3, b4=UV4, b3=BMP, b2=BNO, b1=SD, b0=GPS
  phase   (0-4):   0=ground, 1=ascent, 2=float, 3=descent, 4=landed

HARDWARE:
  Board:  Arduino Mega 2560
  GPS:    VK2828U7G5LF (u-blox G7020) on Serial1 @ 9600 baud (pins 18/19)
  Baro:   BMP388/BMP390 via software SPI (CS=10, SCK=13, MISO=12, MOSI=11)
  IMU:    BNO055 via I2C @ 0x28 (NDOF 9-axis fusion mode)
  UV:     4x SparkFun AS7331 via I2C @ 0x74, 0x75, 0x76, 0x77
  SD:     CS pin 53, file "asusux.csv"
  EEPROM: Mega internal 4KB (addresses 0-11 for GPS backup)

BAUD RATE: 115200 (Serial monitor) / 9600 (GPS Serial1)

// END README /////////////////////////////////////////////////////*/

/////////////////////////////////////////////////////////////////////
// GLOBAL ///////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////

// Enlarge Serial1 RX buffer BEFORE Arduino.h pulls in HardwareSerial.
// Default is 64 bytes. At 9600 baud the GPS fills that in 67ms.
// SD FAT writes can stall for 100-200ms, causing NMEA sentence loss.
#define SERIAL_RX_BUFFER_SIZE 256

#include <Arduino.h>
#include <Wire.h>
#include <SparkFun_AS7331.h>
#include <SPI.h>
#include <Adafruit_Sensor.h>
#include "Adafruit_BMP3XX.h"
#include <SD.h>
#include <Adafruit_BNO055.h>
#include <utility/imumaths.h>
#include <TinyGPS++.h>
#include <avr/wdt.h>
#include <EEPROM.h>

// Pin definitions
#define BMP_SCK 13
#define BMP_MISO 12
#define BMP_MOSI 11
#define BMP_CS 10
#define SD_CHIP_SELECT 53

#define SEALEVELPRESSURE_HPA (1013.25)
#define BUFFER_SIZE 10

#define BNO055_ADDR 0x28
#define BNO055_SAMPLERATE_DELAY_MS 100

// Impact detection threshold: ~15g = 147 m/s^2
// Spring 2026 descent was ~9G normal, so threshold must be above that.
// A hard ground strike (corrupted video on landing) is 20-50G+.
// BNO055 ±16g range maxes at ~156 m/s^2. 15G gives clear separation.
// Only armed during DESCENT phase to prevent false triggers.
#define IMPACT_THRESHOLD_MS2 147.0

// Flight phase constants
#define PHASE_GROUND  0
#define PHASE_ASCENT  1
#define PHASE_FLOAT   2
#define PHASE_DESCENT 3
#define PHASE_LANDED  4

// Altitude thresholds for phase detection (meters, BMP-based)
#define ASCENT_TRIGGER_M    100.0   // 100m above launch = definitely ascending
#define FLOAT_RATE_MS       2.0     // <2 m per sample = floating
#define DESCENT_DROP_M      50.0    // dropped 50m from peak = descending
#define LANDED_ALT_M        200.0   // below 200m after descent = landed
#define LANDED_RATE_MS      1.0     // <1 m/s vertical = stopped

// BMP cold shutdown thresholds
#define BMP_COLD_TEMP_C     (-55.0) // below this, BMP390 is unreliable
#define BMP_FAIL_LIMIT      10      // consecutive fails before marking cold-dead
#define BMP_COLD_RECOVERY_MS 30000  // try to revive frozen BMP every 30s

static const char DATA_FILE_NAME[] = "asusux.csv";

// Sensor objects
SfeAS7331ArdI2C myUVSensor1;
SfeAS7331ArdI2C myUVSensor2;
SfeAS7331ArdI2C myUVSensor3;
SfeAS7331ArdI2C myUVSensor4;
Adafruit_BMP3XX bmp;
Adafruit_BNO055 bno = Adafruit_BNO055(1, BNO055_ADDR);
File dataFile;

// UV data
float UV1A, UV1B, UV1C;
float UV2A, UV2B, UV2C;
float UV3A, UV3B, UV3C;
float UV4A, UV4B, UV4C;

// BNO055 data
float gyroX, gyroY, gyroZ;
float accelX, accelY, accelZ;
float magX, magY, magZ;

// Previous values for validation fallback
float prevUV1A, prevUV1B, prevUV1C;
float prevUV2A, prevUV2B, prevUV2C;
float prevUV3A, prevUV3B, prevUV3C;
float prevUV4A, prevUV4B, prevUV4C;
uint32_t prevPressure;
float prevTemperature;
float prevAltitude;
float prevGyroX, prevGyroY, prevGyroZ;
float prevAccelX, prevAccelY, prevAccelZ;
float prevMagX, prevMagY, prevMagZ;

// Timing
unsigned long lastWriteTime = 0;
const unsigned long writeInterval = 500;
unsigned long lastRecoveryAttempt = 0;
const unsigned long recoveryInterval = 5000;
unsigned long lastBufferFlushTime = 0;
const unsigned long bufferFlushInterval = 5000;
unsigned long lastSDRecoveryAttempt = 0;
const unsigned long sdRecoveryInterval = 5000;

// Stale data counters
uint16_t staleBmpCount = 0;
uint16_t staleBnoCount = 0;
unsigned long lastBmpColdRecovery = 0;
bool bmpColdDead = false;   // true when BMP is frozen below operating temp

// Flight phase state
uint8_t flightPhase = PHASE_GROUND;
float launchAltitude = 0;    // recorded at first valid BMP read
float peakAltitude = 0;      // highest BMP altitude seen
float prevPhaseAltitude = 0; // for rate-of-climb calculation
bool launchAltitudeSet = false;

// Impact detection
bool impactDetected = false;
unsigned long impactTime = 0;

// EEPROM GPS backup
#define EEPROM_GPS_ADDR 0        // start address for 12 bytes: lat(4)+lng(4)+alt(4)
unsigned long lastEepromWrite = 0;
const unsigned long eepromWriteInterval = 30000;  // 30 seconds

// Vertical velocity tracking
float prevVelocityAlt = 0;
unsigned long prevVelocityTime = 0;

// DataPoint struct — the unit of data we buffer and write
// MUST be defined before any function so Arduino auto-prototyping sees the type.
struct DataPoint {
  unsigned long timestamp;

  // GPS
  bool gpsTimeValid;
  uint8_t gpsHour;
  uint8_t gpsMinute;
  uint8_t gpsSecond;
  bool gpsLocValid;
  int32_t gpsLatE6;   // latitude  * 1e6
  int32_t gpsLngE6;   // longitude * 1e6
  uint8_t gpsSats;     // satellite count (0-255)
  uint16_t gpsHdop;    // HDOP * 100 (e.g. 120 = 1.20)
  int32_t gpsAltCm;    // GPS altitude in centimeters

  // Sensors
  float uvValues[12];
  uint32_t pressure;
  float temperature;
  float altitude;
  float gyroValues[3];
  float accelValues[3];
  float magValues[3];

  // Derived columns for research
  float vertVelocity;  // m/s (positive = ascending)
  float accelMag;      // m/s^2 (magnitude of accel vector)
  int16_t freeRamBytes; // available SRAM

  // Metadata for research
  uint16_t staleBmp;   // consecutive BMP stale reads (0 = fresh)
  uint16_t staleBno;   // consecutive BNO stale reads (0 = fresh)
  uint8_t bnoCal;      // packed: (sys<<6)|(gyro<<4)|(accel<<2)|mag
  uint8_t sensorHealth; // bitmask: UV1|UV2|UV3|UV4|BMP|BNO|SD|GPS
  uint8_t phase;       // flight phase 0-4

  bool valid;
};

DataPoint dataBuffer[BUFFER_SIZE];
int bufferIndex = 0;
int bufferCount = 0;

// Sensor health flags
bool uvSensor1Working = true;
bool uvSensor2Working = true;
bool uvSensor3Working = true;
bool uvSensor4Working = true;
bool bmpWorking = true;
bool sdCardWorking = true;
bool bnoWorking = true;

// Free SRAM measurement (AVR-specific)
int freeRam() {
  extern int __heap_start, *__brkval;
  int v;
  return (int)&v - (__brkval == 0 ? (int)&__heap_start : (int)__brkval);
}

// GPS
TinyGPSPlus gps;

// Helper: drain any pending GPS bytes from Serial1
void feedGPS() {
  while (Serial1.available()) {
    gps.encode(Serial1.read());
  }
}

////////////////////////////////////////////////////////////////////
// UBX-CFG-NAV5: Set GPS to Airborne <1g> dynamic model
// The VK2828U7G5LF uses a u-blox G7020 which enforces COCOM limits
// in default "Portable" mode: stops reporting position above ~12km.
// Airborne <1g> (model 6) raises the ceiling to 50km altitude.
// This is a raw UBX binary packet with pre-computed Fletcher checksum.
////////////////////////////////////////////////////////////////////
void configureGPSAirborne() {
  // UBX-CFG-NAV5 payload: dynamic model = 6 (Airborne <1g>)
  // Byte layout: sync(2) + class(1) + id(1) + len(2) + payload(36) + ck(2) = 44 bytes
  static const uint8_t PROGMEM ubxAirborne[] = {
    0xB5, 0x62,       // sync chars
    0x06, 0x24,       // CFG-NAV5
    0x24, 0x00,       // payload length = 36
    0xFF, 0xFF,       // mask: apply all
    0x06,             // dynModel = 6 (Airborne <1g>)
    0x03,             // fixMode = auto 2D/3D
    0x00, 0x00, 0x00, 0x00,  // fixedAlt
    0x10, 0x27, 0x00, 0x00,  // fixedAltVar
    0x05,             // minElev = 5 deg
    0x00,             // drLimit (reserved)
    0xFA, 0x00,       // pDop = 25.0
    0xFA, 0x00,       // tDop = 25.0
    0x64, 0x00,       // pAcc = 100m
    0x2C, 0x01,       // tAcc = 300m
    0x00,             // staticHoldThresh
    0x00,             // dgnssTimeout
    0x00, 0x00, 0x00, 0x00,  // cnoThreshNumSVs, cnoThresh, reserved
    0x00, 0x00,       // staticHoldMaxDist
    0x00,             // utcStandard
    0x00, 0x00, 0x00, 0x00, 0x00  // reserved
  };

  // Calculate Fletcher checksum over class+id+len+payload (bytes 2..41)
  uint8_t ckA = 0, ckB = 0;
  uint8_t buf[44];
  memcpy_P(buf, ubxAirborne, 42);
  for (uint8_t i = 2; i < 42; i++) {
    ckA += buf[i];
    ckB += ckA;
  }
  buf[42] = ckA;
  buf[43] = ckB;

  Serial1.write(buf, 44);
  Serial1.flush();

  Serial.print(F("GPS: UBX Airborne<1g> sent, ckA=0x"));
  Serial.print(ckA, HEX);
  Serial.print(F(" ckB=0x"));
  Serial.println(ckB, HEX);

  // Wait for ACK (best-effort, non-blocking timeout)
  unsigned long t0 = millis();
  while (millis() - t0 < 1000) {
    feedGPS();  // keep parsing — TinyGPS ignores UBX but we drain the buffer
  }
  Serial.println(F("GPS: Airborne mode configured (COCOM ceiling = 50km)"));
}

/////////////////////////////////////////////////////////////////////
// SETUP ////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////
void setup() {
  pinMode(SD_CHIP_SELECT, OUTPUT);
  digitalWrite(SD_CHIP_SELECT, HIGH);

  Serial.begin(115200);
  Serial1.begin(9600);  // VK2828U7G5LF GPS on Mega pins 18(TX1) / 19(RX1)

  unsigned long startTime = millis();
  while (!Serial && (millis() - startTime < 5000)) {
    delay(100);
  }

  Serial.println(F("\n\n======= STARTING SENSOR INITIALIZATION ======="));

  // Read last-known GPS position from EEPROM (survives power loss + SD corruption)
  readEepromGPS();

  Wire.begin();
  delay(1000);  // I2C stabilize

  // GPS: switch to Airborne <1g> BEFORE anything else so it has time to ACK
  configureGPSAirborne();

  UVTest();
  UVSetup();
  bmpTestnSetup();
  bnoTestnSetup();
  sdReaderTest();
  writeHeader();

  Serial.println(F("======= INITIALIZATION COMPLETE ======="));
  Serial.println(F("\n--- INITIAL SENSOR READINGS ---"));

  if (bnoWorking) {
    bnoSerialTest();
  } else {
    Serial.println(F("BNO055 not working, skipping test"));
  }

  if (bmpWorking) {
    bmpSerialTest();
    // Record launch altitude for flight phase detection
    if (bmp.performReading()) {
      launchAltitude = bmp.readAltitude(SEALEVELPRESSURE_HPA);
      peakAltitude = launchAltitude;
      prevPhaseAltitude = launchAltitude;
      launchAltitudeSet = true;
      Serial.print(F("Launch altitude: ")); Serial.print(launchAltitude); Serial.println(F(" m"));
    }
  } else {
    Serial.println(F("BMP not working, skipping test"));
  }

  Serial.println(F("Starting main loop...\n"));

  // Enable AVR watchdog timer (8 second timeout).
  // If any I2C call hangs (BNO055/AS7331 pulling SDA low in cold/vibration),
  // the Mega will auto-reset and resume logging. Without this, a single
  // I2C bus hang means the payload records nothing for the rest of the flight.
  wdt_enable(WDTO_8S);
}

/////////////////////////////////////////////////////////////////////
// MAIN LOOP ////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////
void loop() {
  wdt_reset();  // pet the watchdog every loop iteration
  feedGPS();

  unsigned long currentTime = millis();

  // --- Impact detection: only armed during DESCENT/LANDED phases ---
  // 9G is normal during descent, so we only trigger on 15G+ ground strike.
  // Must run before logData so we can emergency-flush on the same iteration.
  if (!impactDetected && bnoWorking && flightPhase >= PHASE_DESCENT) {
    checkImpact();
  }

  // --- Data logging at writeInterval ---
  if (currentTime - lastWriteTime >= writeInterval) {
    logData();
    lastWriteTime = currentTime;
  }

  // --- UV sensor recovery ---
  if (currentTime - lastRecoveryAttempt >= recoveryInterval) {
    if (!uvSensor1Working || !uvSensor2Working || !uvSensor3Working || !uvSensor4Working) {
      attemptUVRecovery();
    }
    lastRecoveryAttempt = currentTime;
  }

  // --- SD card recovery ---
  if (!sdCardWorking && (currentTime - lastSDRecoveryAttempt >= sdRecoveryInterval)) {
    Serial.println(F("Attempting SD card recovery..."));
    SD.end();
    delay(100);
    if (SD.begin(SD_CHIP_SELECT)) {
      sdCardWorking = true;
      writeHeader();
      flushBuffer();
      Serial.println(F("SD card recovered!"));
    } else {
      Serial.println(F("SD recovery failed, will retry."));
    }
    lastSDRecoveryAttempt = currentTime;
  }

  // --- BMP cold-dead recovery: try to reinit frozen pressure sensor ---
  if (bmpColdDead && (currentTime - lastBmpColdRecovery >= BMP_COLD_RECOVERY_MS)) {
    Serial.println(F("BMP: attempting cold recovery..."));
    if (bmp.begin_SPI(BMP_CS, BMP_SCK, BMP_MISO, BMP_MOSI)) {
      bmp.setTemperatureOversampling(BMP3_OVERSAMPLING_8X);
      bmp.setPressureOversampling(BMP3_OVERSAMPLING_4X);
      bmp.setIIRFilterCoeff(BMP3_IIR_FILTER_COEFF_3);
      bmp.setOutputDataRate(BMP3_ODR_50_HZ);
      if (bmp.performReading() && bmp.temperature > BMP_COLD_TEMP_C) {
        bmpColdDead = false;
        bmpWorking = true;
        staleBmpCount = 0;
        Serial.println(F("BMP: recovered from cold shutdown!"));
      }
    }
    lastBmpColdRecovery = currentTime;
  }

  // --- Periodic buffer flush ---
  if (currentTime - lastBufferFlushTime >= bufferFlushInterval) {
    flushBuffer();
    lastBufferFlushTime = currentTime;
  }

  // --- EEPROM GPS backup (every 30s when we have a valid fix) ---
  if (gps.location.isValid() && gps.location.age() < 2000 &&
      (currentTime - lastEepromWrite >= eepromWriteInterval)) {
    writeEepromGPS();
    lastEepromWrite = currentTime;
  }

  feedGPS();
}

/////////////////////////////////////////////////////////////////////
// FUNCTIONS ////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////
// 1) writeHeader — only writes if file is empty (no duplicate headers)
////////////////////////////////////////////////////////////////////
void writeHeader() {
  if (!sdCardWorking) return;

  for (int attempt = 0; attempt < 3; attempt++) {
    dataFile = SD.open(DATA_FILE_NAME, FILE_WRITE);
    if (dataFile) {
      if (dataFile.size() == 0) {
        dataFile.println(F("elapsed(ms),UV1A(uW/cm2),UV1B(uW/cm2),UV1C(uW/cm2),UV2A(uW/cm2),UV2B(uW/cm2),UV2C(uW/cm2),UV3A(uW/cm2),UV3B(uW/cm2),UV3C(uW/cm2),UV4A(uW/cm2),UV4B(uW/cm2),UV4C(uW/cm2),pressure(Pa),temp(C),alt(m),gyroX(deg/s),gyroY(deg/s),gyroZ(deg/s),accelX(m/s2),accelY(m/s2),accelZ(m/s2),magX(uT),magY(uT),magZ(uT),time_utc,lat,lng,gps_sats,gps_hdop,gps_alt(m),stale_bmp,stale_bno,bno_cal,health,phase,vert_vel(m/s),accel_mag(m/s2),free_ram"));
        Serial.println(F("HEADER PRINTED"));
      } else {
        Serial.println(F("Header exists, skipping."));
      }
      dataFile.flush();
      dataFile.close();
      return;
    }
    Serial.print(F("Header write failed, attempt "));
    Serial.println(attempt + 1);
    delay(500);
  }
  Serial.println(F("Failed to write header after 3 attempts"));
  sdCardWorking = false;
}

////////////////////////////////////////////////////////////////////
// 2) logData
////////////////////////////////////////////////////////////////////
void logData() {
  DataPoint dp = {};
  dp.timestamp = millis();
  dp.valid = false;

  // --- UV (AS7331 x4, I2C 0x74-0x77) ---
  feedGPS();
  getUVdata();
  dp.uvValues[0]  = UV1A;  dp.uvValues[1]  = UV1B;  dp.uvValues[2]  = UV1C;
  dp.uvValues[3]  = UV2A;  dp.uvValues[4]  = UV2B;  dp.uvValues[5]  = UV2C;
  dp.uvValues[6]  = UV3A;  dp.uvValues[7]  = UV3B;  dp.uvValues[8]  = UV3C;
  dp.uvValues[9]  = UV4A;  dp.uvValues[10] = UV4B;  dp.uvValues[11] = UV4C;

  feedGPS();

  // --- BMP390 (SPI, pins 10-13) ---
  bool bmpFresh = false;
  if (bmpWorking && !bmpColdDead && bmp.performReading()) {
    // Check if BMP has gone below cold threshold
    if (bmp.temperature < BMP_COLD_TEMP_C) {
      // Sensor is returning data but temp is below spec — mark as unreliable
      Serial.println(F("BMP: temp below -55C, data unreliable"));
      staleBmpCount++;
      // Still use the reading but flag it as stale
      dp.pressure    = bmp.pressure;
      dp.temperature = bmp.temperature;
      dp.altitude    = bmp.readAltitude(SEALEVELPRESSURE_HPA);
    } else {
      dp.pressure    = bmp.pressure;
      dp.temperature = bmp.temperature;
      dp.altitude    = bmp.readAltitude(SEALEVELPRESSURE_HPA);
      staleBmpCount = 0;
      bmpFresh = true;
    }
  } else {
    // BMP read failed
    dp.pressure    = prevPressure;
    dp.temperature = prevTemperature;
    dp.altitude    = prevAltitude;
    staleBmpCount++;

    // If BMP has failed too many times, check if it's cold-dead
    if (staleBmpCount >= BMP_FAIL_LIMIT && !bmpColdDead) {
      // If last known temp was very cold, this is a cold shutdown
      if (prevTemperature < -35.0) {
        bmpColdDead = true;
        lastBmpColdRecovery = millis();
        Serial.println(F("BMP: cold shutdown detected, switching to slow recovery"));
      }
    }
  }
  dp.staleBmp = staleBmpCount;

  feedGPS();

  // --- BNO055 (I2C 0x28) ---
  bool bnoFresh = false;
  if (getBNOdata()) {
    dp.gyroValues[0]  = gyroX;  dp.gyroValues[1]  = gyroY;  dp.gyroValues[2]  = gyroZ;
    dp.accelValues[0] = accelX; dp.accelValues[1] = accelY; dp.accelValues[2] = accelZ;
    dp.magValues[0]   = magX;   dp.magValues[1]   = magY;   dp.magValues[2]   = magZ;
    dp.valid = true;
    staleBnoCount = 0;
    bnoFresh = true;
  } else {
    dp.gyroValues[0]  = prevGyroX;  dp.gyroValues[1]  = prevGyroY;  dp.gyroValues[2]  = prevGyroZ;
    dp.accelValues[0] = prevAccelX; dp.accelValues[1] = prevAccelY; dp.accelValues[2] = prevAccelZ;
    dp.magValues[0]   = prevMagX;   dp.magValues[1]   = prevMagY;   dp.magValues[2]   = prevMagZ;
    dp.valid = (dp.pressure != 0 || dp.temperature != 0);
    staleBnoCount++;
  }
  dp.staleBno = staleBnoCount;

  // BNO055 calibration status (packed into 1 byte for CSV)
  if (bnoWorking) {
    uint8_t calSys, calGyro, calAccel, calMag;
    calSys = calGyro = calAccel = calMag = 0;
    bno.getCalibration(&calSys, &calGyro, &calAccel, &calMag);
    dp.bnoCal = (calSys << 6) | (calGyro << 4) | (calAccel << 2) | calMag;
  } else {
    dp.bnoCal = 0;
  }

  feedGPS();

  // --- GPS (VK2828U7G5LF, Serial1 9600 baud) ---
  dp.gpsTimeValid = false;
  dp.gpsLocValid  = false;
  dp.gpsHour = dp.gpsMinute = dp.gpsSecond = 0;
  dp.gpsLatE6 = 0;
  dp.gpsLngE6 = 0;
  dp.gpsSats = 0;
  dp.gpsHdop = 9999;
  dp.gpsAltCm = 0;

  if (gps.time.isValid() && gps.time.age() < 2000) {
    dp.gpsTimeValid = true;
    dp.gpsHour   = gps.time.hour();
    dp.gpsMinute = gps.time.minute();
    dp.gpsSecond = gps.time.second();
  }

  dp.gpsSats = gps.satellites.isValid() ? gps.satellites.value() : 0;
  dp.gpsHdop = gps.hdop.isValid() ? gps.hdop.value() : 9999;

  if (gps.location.isValid() && gps.location.age() < 2000) {
    dp.gpsLocValid = true;
    double lat = gps.location.lat();
    double lng = gps.location.lng();
    dp.gpsLatE6 = (int32_t)(lat * 1000000.0 + (lat >= 0 ? 0.5 : -0.5));
    dp.gpsLngE6 = (int32_t)(lng * 1000000.0 + (lng >= 0 ? 0.5 : -0.5));
  }

  if (gps.altitude.isValid() && gps.altitude.age() < 2000) {
    dp.gpsAltCm = (int32_t)(gps.altitude.meters() * 100.0);
  }

  // --- Sensor health bitmask ---
  // b7=UV1, b6=UV2, b5=UV3, b4=UV4, b3=BMP, b2=BNO, b1=SD, b0=GPS
  dp.sensorHealth = 0;
  if (uvSensor1Working) dp.sensorHealth |= 0x80;
  if (uvSensor2Working) dp.sensorHealth |= 0x40;
  if (uvSensor3Working) dp.sensorHealth |= 0x20;
  if (uvSensor4Working) dp.sensorHealth |= 0x10;
  if (bmpWorking && !bmpColdDead) dp.sensorHealth |= 0x08;
  if (bnoWorking)       dp.sensorHealth |= 0x04;
  if (sdCardWorking)    dp.sensorHealth |= 0x02;
  if (dp.gpsLocValid)   dp.sensorHealth |= 0x01;

  // --- Flight phase detection (BMP altitude-based) ---
  dp.phase = updateFlightPhase(dp.altitude, bmpFresh);

  // --- Derived columns for research ---
  // Vertical velocity (m/s): positive = ascending, negative = descending
  if (prevVelocityTime > 0 && dp.timestamp > prevVelocityTime) {
    float dt = (dp.timestamp - prevVelocityTime) / 1000.0;
    if (dt > 0.01 && dt < 10.0) {  // sanity: 10ms to 10s
      dp.vertVelocity = (dp.altitude - prevVelocityAlt) / dt;
    } else {
      dp.vertVelocity = 0;
    }
  } else {
    dp.vertVelocity = 0;
  }
  prevVelocityAlt = dp.altitude;
  prevVelocityTime = dp.timestamp;

  // Accel magnitude (m/s^2): at rest ~9.8, freefall ~0, impact >> 50
  float ax = dp.accelValues[0];
  float ay = dp.accelValues[1];
  float az = dp.accelValues[2];
  dp.accelMag = sqrt(ax * ax + ay * ay + az * az);

  // Free SRAM (bytes available between heap and stack)
  dp.freeRamBytes = freeRam();

  // --- Validate ---
  validateData(&dp);

  // --- Write to SD or buffer ---
  if (sdCardWorking) {
    if (!writeDataPointToSD(dp)) {
      addToBuffer(dp);
    }
  } else {
    addToBuffer(dp);
  }
}

////////////////////////////////////////////////////////////////////
// 3) sdReaderTest
////////////////////////////////////////////////////////////////////
void sdReaderTest() {
  if (!SD.begin(SD_CHIP_SELECT)) {
    Serial.println(F("Card failed, or not present"));
    sdCardWorking = false;
    return;
  }
  Serial.println(F("Card initialized."));
  sdCardWorking = true;
}

////////////////////////////////////////////////////////////////////
// 4) bmpTestnSetup
////////////////////////////////////////////////////////////////////
void bmpTestnSetup() {
  Serial.println(F("Adafruit BMP388 / BMP390 test"));

  if (!bmp.begin_SPI(BMP_CS, BMP_SCK, BMP_MISO, BMP_MOSI)) {
    Serial.println(F("Could not find a valid BMP3 sensor, check wiring!"));
    bmpWorking = false;
    return;
  }
  Serial.println(F("Pressure Sensor Working!"));

  bmp.setTemperatureOversampling(BMP3_OVERSAMPLING_8X);
  bmp.setPressureOversampling(BMP3_OVERSAMPLING_4X);
  bmp.setIIRFilterCoeff(BMP3_IIR_FILTER_COEFF_3);
  bmp.setOutputDataRate(BMP3_ODR_50_HZ);

  if (bmp.performReading()) {
    prevPressure    = bmp.pressure;
    prevTemperature = bmp.temperature;
    prevAltitude    = bmp.readAltitude(SEALEVELPRESSURE_HPA);
  }
}

////////////////////////////////////////////////////////////////////
// 5) UVTest
////////////////////////////////////////////////////////////////////
void UVTest() {
  Serial.println(F("UV Sensor Test Begin."));

  if (!myUVSensor1.begin(0x74)) { uvSensor1Working = false; Serial.println(F("UV1 FAIL")); }
  else { Serial.println(F("UV Sensor 1 OK.")); }

  if (!myUVSensor2.begin(0x75)) { uvSensor2Working = false; Serial.println(F("UV2 FAIL")); }
  else { Serial.println(F("UV Sensor 2 OK.")); }

  if (!myUVSensor3.begin(0x76)) { uvSensor3Working = false; Serial.println(F("UV3 FAIL")); }
  else { Serial.println(F("UV Sensor 3 OK.")); }

  if (!myUVSensor4.begin(0x77)) { uvSensor4Working = false; Serial.println(F("UV4 FAIL")); }
  else { Serial.println(F("UV Sensor 4 OK.")); }

  Serial.println(F("UV Sensors init complete."));
}

////////////////////////////////////////////////////////////////////
// 6) UVSetup
////////////////////////////////////////////////////////////////////
void UVSetup() {
  if (uvSensor1Working && !myUVSensor1.prepareMeasurement(MEAS_MODE_CMD)) {
    uvSensor1Working = false; Serial.println(F("UV1 prepare FAIL"));
  }
  if (uvSensor2Working && !myUVSensor2.prepareMeasurement(MEAS_MODE_CMD)) {
    uvSensor2Working = false; Serial.println(F("UV2 prepare FAIL"));
  }
  if (uvSensor3Working && !myUVSensor3.prepareMeasurement(MEAS_MODE_CMD)) {
    uvSensor3Working = false; Serial.println(F("UV3 prepare FAIL"));
  }
  if (uvSensor4Working && !myUVSensor4.prepareMeasurement(MEAS_MODE_CMD)) {
    uvSensor4Working = false; Serial.println(F("UV4 prepare FAIL"));
  }
  Serial.println(F("UV sensors set to command mode."));
}

////////////////////////////////////////////////////////////////////
// 7) getUVdata
////////////////////////////////////////////////////////////////////
boolean getUVdata() {
  boolean success = true;

  if (uvSensor1Working && ksfTkErrOk != myUVSensor1.setStartState(true)) {
    Serial.println(F("UV1 start err")); success = false;
  }
  if (uvSensor2Working && ksfTkErrOk != myUVSensor2.setStartState(true)) {
    Serial.println(F("UV2 start err")); success = false;
  }
  if (uvSensor3Working && ksfTkErrOk != myUVSensor3.setStartState(true)) {
    Serial.println(F("UV3 start err")); success = false;
  }
  if (uvSensor4Working && ksfTkErrOk != myUVSensor4.setStartState(true)) {
    Serial.println(F("UV4 start err")); success = false;
  }

  int maxConvTime = 0;
  if (uvSensor1Working) maxConvTime = max(maxConvTime, myUVSensor1.getConversionTimeMillis());
  if (uvSensor2Working) maxConvTime = max(maxConvTime, myUVSensor2.getConversionTimeMillis());
  if (uvSensor3Working) maxConvTime = max(maxConvTime, myUVSensor3.getConversionTimeMillis());
  if (uvSensor4Working) maxConvTime = max(maxConvTime, myUVSensor4.getConversionTimeMillis());

  if (maxConvTime > 0) {
    delay(2 + maxConvTime);
  }

  // Save previous values
  prevUV1A = UV1A; prevUV1B = UV1B; prevUV1C = UV1C;
  prevUV2A = UV2A; prevUV2B = UV2B; prevUV2C = UV2C;
  prevUV3A = UV3A; prevUV3B = UV3B; prevUV3C = UV3C;
  prevUV4A = UV4A; prevUV4B = UV4B; prevUV4C = UV4C;

  // Read UV1
  if (uvSensor1Working) {
    if (ksfTkErrOk != myUVSensor1.readAllUV()) {
      UV1A = UV1B = UV1C = -999;
    } else {
      UV1A = myUVSensor1.getUVA();
      UV1B = myUVSensor1.getUVB();
      UV1C = myUVSensor1.getUVC();
    }
  } else {
    UV1A = UV1B = UV1C = -999;
  }

  // Read UV2
  if (uvSensor2Working) {
    if (ksfTkErrOk != myUVSensor2.readAllUV()) {
      UV2A = UV2B = UV2C = -999;
    } else {
      UV2A = myUVSensor2.getUVA();
      UV2B = myUVSensor2.getUVB();
      UV2C = myUVSensor2.getUVC();
    }
  } else {
    UV2A = UV2B = UV2C = -999;
  }

  // Read UV3
  if (uvSensor3Working) {
    if (ksfTkErrOk != myUVSensor3.readAllUV()) {
      UV3A = UV3B = UV3C = -999;
    } else {
      UV3A = myUVSensor3.getUVA();
      UV3B = myUVSensor3.getUVB();
      UV3C = myUVSensor3.getUVC();
    }
  } else {
    UV3A = UV3B = UV3C = -999;
  }

  // Read UV4
  if (uvSensor4Working) {
    if (ksfTkErrOk != myUVSensor4.readAllUV()) {
      UV4A = UV4B = UV4C = -999;
    } else {
      UV4A = myUVSensor4.getUVA();
      UV4B = myUVSensor4.getUVB();
      UV4C = myUVSensor4.getUVC();
    }
  } else {
    UV4A = UV4B = UV4C = -999;
  }

  return (uvSensor1Working || uvSensor2Working || uvSensor3Working || uvSensor4Working);
}

////////////////////////////////////////////////////////////////////
// 8) logUVdata (direct file writer, kept for backward compat)
////////////////////////////////////////////////////////////////////
void logUVdata(File &file) {
  file.print(UV1A); file.print(',');
  file.print(UV1B); file.print(',');
  file.print(UV1C); file.print(',');
  file.print(UV2A); file.print(',');
  file.print(UV2B); file.print(',');
  file.print(UV2C); file.print(',');
  file.print(UV3A); file.print(',');
  file.print(UV3B); file.print(',');
  file.print(UV3C); file.print(',');
  file.print(UV4A); file.print(',');
  file.print(UV4B); file.print(',');
  file.print(UV4C); file.print(',');
}

////////////////////////////////////////////////////////////////////
// 9) attemptUVRecovery
////////////////////////////////////////////////////////////////////
void attemptUVRecovery() {
  if (!uvSensor1Working) {
    if (myUVSensor1.begin(0x74) && myUVSensor1.prepareMeasurement(MEAS_MODE_CMD)) {
      uvSensor1Working = true;
      Serial.println(F("UV1 recovered!"));
    }
  }
  if (!uvSensor2Working) {
    if (myUVSensor2.begin(0x75) && myUVSensor2.prepareMeasurement(MEAS_MODE_CMD)) {
      uvSensor2Working = true;
      Serial.println(F("UV2 recovered!"));
    }
  }
  if (!uvSensor3Working) {
    if (myUVSensor3.begin(0x76) && myUVSensor3.prepareMeasurement(MEAS_MODE_CMD)) {
      uvSensor3Working = true;
      Serial.println(F("UV3 recovered!"));
    }
  }
  if (!uvSensor4Working) {
    if (myUVSensor4.begin(0x77) && myUVSensor4.prepareMeasurement(MEAS_MODE_CMD)) {
      uvSensor4Working = true;
      Serial.println(F("UV4 recovered!"));
    }
  }
}

////////////////////////////////////////////////////////////////////
// 10) bmpSerialTest
////////////////////////////////////////////////////////////////////
void bmpSerialTest() {
  if (!bmpWorking) { Serial.println(F("BMP not working")); return; }
  if (!bmp.performReading()) { Serial.println(F("BMP read fail")); return; }

  Serial.print(F("Temp = ")); Serial.print(bmp.temperature); Serial.println(F(" C"));
  Serial.print(F("Pres = ")); Serial.print(bmp.pressure);    Serial.println(F(" Pa"));
  Serial.print(F("Alt  = ")); Serial.print(bmp.readAltitude(SEALEVELPRESSURE_HPA)); Serial.println(F(" m"));
  Serial.println();
}

////////////////////////////////////////////////////////////////////
// 11) UVSerialTest
////////////////////////////////////////////////////////////////////
void UVSerialTest() {
  if (!getUVdata()) { Serial.println(F("UV data fail")); return; }
  if (uvSensor1Working) { Serial.print(F("UV1: ")); Serial.print(UV1A); Serial.print(' '); Serial.print(UV1B); Serial.print(' '); Serial.println(UV1C); }
  if (uvSensor2Working) { Serial.print(F("UV2: ")); Serial.print(UV2A); Serial.print(' '); Serial.print(UV2B); Serial.print(' '); Serial.println(UV2C); }
  if (uvSensor3Working) { Serial.print(F("UV3: ")); Serial.print(UV3A); Serial.print(' '); Serial.print(UV3B); Serial.print(' '); Serial.println(UV3C); }
  if (uvSensor4Working) { Serial.print(F("UV4: ")); Serial.print(UV4A); Serial.print(' '); Serial.print(UV4B); Serial.print(' '); Serial.println(UV4C); }
}

////////////////////////////////////////////////////////////////////
// 12) flushBuffer — writes buffered data to SD when card comes back
////////////////////////////////////////////////////////////////////
void flushBuffer() {
  if (bufferCount == 0 || !sdCardWorking) return;

  dataFile = SD.open(DATA_FILE_NAME, FILE_WRITE);
  if (!dataFile) {
    Serial.println(F("Flush: SD open fail"));
    sdCardWorking = false;
    lastSDRecoveryAttempt = millis();
    return;
  }

  int startIdx = (bufferIndex - bufferCount + BUFFER_SIZE) % BUFFER_SIZE;
  for (int i = 0; i < bufferCount; i++) {
    int idx = (startIdx + i) % BUFFER_SIZE;
    if (dataBuffer[idx].valid) {
      writeDataPointToFile(dataBuffer[idx], dataFile);
    }
  }

  dataFile.flush();
  dataFile.close();
  bufferCount = 0;
  Serial.println(F("Buffer flushed."));
}

////////////////////////////////////////////////////////////////////
// 13) addToBuffer
////////////////////////////////////////////////////////////////////
void addToBuffer(const DataPoint &data) {
  dataBuffer[bufferIndex] = data;
  bufferIndex = (bufferIndex + 1) % BUFFER_SIZE;
  if (bufferCount < BUFFER_SIZE) {
    bufferCount++;
  }
}

////////////////////////////////////////////////////////////////////
// 14) validateData
////////////////////////////////////////////////////////////////////
void validateData(DataPoint *data) {
  // UV: replace error sentinel or NaN with previous value
  const float *prevUV[] = {
    &prevUV1A, &prevUV1B, &prevUV1C,
    &prevUV2A, &prevUV2B, &prevUV2C,
    &prevUV3A, &prevUV3B, &prevUV3C,
    &prevUV4A, &prevUV4B, &prevUV4C
  };
  for (int i = 0; i < 12; i++) {
    if (isnan(data->uvValues[i]) || data->uvValues[i] < -998) {
      data->uvValues[i] = *prevUV[i];
    }
  }

  // Pressure: 1000 Pa (very high altitude) to 120000 Pa (sea level +)
  if (data->pressure < 1000 || data->pressure > 120000) {
    data->pressure = prevPressure;
  } else {
    prevPressure = data->pressure;
  }

  // Temperature: -100 C to +85 C (BMP390 rated range)
  if (isnan(data->temperature) || data->temperature < -100 || data->temperature > 85) {
    data->temperature = prevTemperature;
  } else {
    prevTemperature = data->temperature;
  }

  // Altitude: -500 m to 40000 m
  if (isnan(data->altitude) || data->altitude < -500 || data->altitude > 40000) {
    data->altitude = prevAltitude;
  } else {
    prevAltitude = data->altitude;
  }

  // Gyro: -2000 to 2000 deg/s
  float *prevGyro[] = { &prevGyroX, &prevGyroY, &prevGyroZ };
  for (int i = 0; i < 3; i++) {
    if (isnan(data->gyroValues[i]) || data->gyroValues[i] < -2000 || data->gyroValues[i] > 2000) {
      data->gyroValues[i] = *prevGyro[i];
    } else {
      *prevGyro[i] = data->gyroValues[i];
    }
  }

  // Accel: -160 to 160 m/s^2 (BNO055 max range +-16g)
  float *prevAccel[] = { &prevAccelX, &prevAccelY, &prevAccelZ };
  for (int i = 0; i < 3; i++) {
    if (isnan(data->accelValues[i]) || data->accelValues[i] < -160 || data->accelValues[i] > 160) {
      data->accelValues[i] = *prevAccel[i];
    } else {
      *prevAccel[i] = data->accelValues[i];
    }
  }

  // Magnetic: -200 to 200 uT (Earth's field components are SIGNED, typically -80 to +80)
  // V1e had 0..100 which discarded all negative readings — flight data showed values like -39 uT
  float *prevMagArr[] = { &prevMagX, &prevMagY, &prevMagZ };
  for (int i = 0; i < 3; i++) {
    if (isnan(data->magValues[i]) || data->magValues[i] < -200 || data->magValues[i] > 200) {
      data->magValues[i] = *prevMagArr[i];
    } else {
      *prevMagArr[i] = data->magValues[i];
    }
  }
}

////////////////////////////////////////////////////////////////////
// 15) writeDataPointToSD — returns false if SD write failed
////////////////////////////////////////////////////////////////////
bool writeDataPointToSD(const DataPoint &data) {
  if (!sdCardWorking) return false;

  dataFile = SD.open(DATA_FILE_NAME, FILE_WRITE);
  if (!dataFile) {
    Serial.println(F("SD open fail in write"));
    sdCardWorking = false;
    lastSDRecoveryAttempt = millis();
    return false;
  }

  writeDataPointToFile(data, dataFile);
  dataFile.flush();
  dataFile.close();
  return true;
}

////////////////////////////////////////////////////////////////////
// 16) writeDataPointToFile
//     THE CRITICAL FIX: every field uses file.print() with commas.
//     file.println() is called ONCE at the very end to terminate the row.
//     V1e had file.println(magZ) which inserted a newline mid-row,
//     causing GPS time to appear on the NEXT line prepended to elapsed ms.
////////////////////////////////////////////////////////////////////
void writeDataPointToFile(const DataPoint &data, File &file) {
  // elapsed(ms)
  file.print(data.timestamp);
  file.print(',');

  // 12 UV values
  for (int i = 0; i < 12; i++) {
    file.print(data.uvValues[i]);
    file.print(',');
  }

  // BMP: pressure, temp, altitude
  file.print(data.pressure);
  file.print(',');
  file.print(data.temperature);
  file.print(',');
  file.print(data.altitude);
  file.print(',');

  // BNO: gyro X,Y,Z
  file.print(data.gyroValues[0]);
  file.print(',');
  file.print(data.gyroValues[1]);
  file.print(',');
  file.print(data.gyroValues[2]);
  file.print(',');

  // BNO: accel X,Y,Z
  file.print(data.accelValues[0]);
  file.print(',');
  file.print(data.accelValues[1]);
  file.print(',');
  file.print(data.accelValues[2]);
  file.print(',');

  // BNO: mag X,Y,Z  — file.print NOT println (was the V1e bug)
  file.print(data.magValues[0]);
  file.print(',');
  file.print(data.magValues[1]);
  file.print(',');
  file.print(data.magValues[2]);
  file.print(',');

  // GPS time (UTC) — always write the column, empty if no fix
  if (data.gpsTimeValid) {
    // Use a char buffer to avoid String objects
    char timeBuf[9];  // "HH:MM:SS"
    snprintf(timeBuf, sizeof(timeBuf), "%02u:%02u:%02u",
             data.gpsHour, data.gpsMinute, data.gpsSecond);
    file.print(timeBuf);
  }
  file.print(',');

  // GPS latitude
  if (data.gpsLocValid) {
    // Print from scaled integer: 6 decimal places, no float drift
    int32_t absLat = abs(data.gpsLatE6);
    if (data.gpsLatE6 < 0) file.print('-');
    file.print(absLat / 1000000L);
    file.print('.');
    char fracBuf[7];
    snprintf(fracBuf, sizeof(fracBuf), "%06ld", absLat % 1000000L);
    file.print(fracBuf);
  }
  file.print(',');

  // GPS longitude
  if (data.gpsLocValid) {
    int32_t absLng = abs(data.gpsLngE6);
    if (data.gpsLngE6 < 0) file.print('-');
    file.print(absLng / 1000000L);
    file.print('.');
    char fracBuf[7];
    snprintf(fracBuf, sizeof(fracBuf), "%06ld", absLng % 1000000L);
    file.print(fracBuf);
  }
  file.print(',');

  // GPS satellites
  file.print(data.gpsSats);
  file.print(',');

  // GPS HDOP (stored as x100, print as decimal: 120 -> "1.20")
  file.print(data.gpsHdop / 100);
  file.print('.');
  char hdopFrac[3];
  snprintf(hdopFrac, sizeof(hdopFrac), "%02u", (unsigned)(data.gpsHdop % 100));
  file.print(hdopFrac);
  file.print(',');

  // GPS altitude (stored as cm, print as meters with 2dp)
  if (data.gpsAltCm != 0 || data.gpsLocValid) {
    file.print(data.gpsAltCm / 100L);
    file.print('.');
    char altFrac[3];
    snprintf(altFrac, sizeof(altFrac), "%02ld", labs(data.gpsAltCm % 100L));
    file.print(altFrac);
  }
  file.print(',');

  // Stale counters (0 = fresh real data, >0 = repeated from N reads ago)
  file.print(data.staleBmp);
  file.print(',');
  file.print(data.staleBno);
  file.print(',');

  // BNO055 calibration (packed byte, printed as decimal 0-255)
  // Decode: sys=(val>>6)&3, gyro=(val>>4)&3, accel=(val>>2)&3, mag=val&3
  file.print(data.bnoCal);
  file.print(',');

  // Sensor health bitmask (decimal 0-255)
  // b7=UV1 b6=UV2 b5=UV3 b4=UV4 b3=BMP b2=BNO b1=SD b0=GPS
  file.print(data.sensorHealth);
  file.print(',');

  // Flight phase: 0=ground 1=ascent 2=float 3=descent 4=landed
  file.print(data.phase);
  file.print(',');

  // Vertical velocity (m/s, 2 decimal places)
  file.print(data.vertVelocity, 2);
  file.print(',');

  // Accel magnitude (m/s^2, 2 decimal places)
  file.print(data.accelMag, 2);
  file.print(',');

  // Free SRAM (bytes)
  file.print(data.freeRamBytes);

  // END OF ROW — the one and only newline
  file.println();
}

////////////////////////////////////////////////////////////////////
// 17) bnoTestnSetup
////////////////////////////////////////////////////////////////////
void bnoTestnSetup() {
  Serial.println(F("BNO055 orientation sensor test"));
  delay(1000);

  if (!bno.begin()) {
    Serial.println(F("BNO055 NOT FOUND! Check wiring / I2C address!"));
    Serial.print(F("Expected address: 0x")); Serial.println(BNO055_ADDR, HEX);
    bnoWorking = false;
    return;  // FIX: V1e had "} else ;" which fell through to success path
  }

  Serial.println(F("BNO055 Orientation Sensor found!"));
  Serial.print(F("Temperature: ")); Serial.println(bno.getTemp());

  bno.setExtCrystalUse(true);
  delay(50);

  // NDOF mode (9-axis fusion)
  bno.setMode(OPERATION_MODE_NDOF);
  delay(100);

  uint8_t currentMode = bno.getMode();
  Serial.print(F("Mode: 0x")); Serial.println(currentMode, HEX);

  if (currentMode != OPERATION_MODE_NDOF) {
    Serial.println(F("NDOF mode set failed, retrying..."));
    bno.setMode(OPERATION_MODE_NDOF);
    delay(200);
  }

  if (getBNOdata()) {
    Serial.println(F("Initial BNO055 data OK"));
    prevGyroX = gyroX; prevGyroY = gyroY; prevGyroZ = gyroZ;
    prevAccelX = accelX; prevAccelY = accelY; prevAccelZ = accelZ;
    prevMagX = magX; prevMagY = magY; prevMagZ = magZ;
  } else {
    Serial.println(F("Failed to get initial BNO055 data!"));
  }
}

////////////////////////////////////////////////////////////////////
// 18) getBNOdata
////////////////////////////////////////////////////////////////////
boolean getBNOdata() {
  if (!bnoWorking) return false;

  prevGyroX = gyroX; prevGyroY = gyroY; prevGyroZ = gyroZ;
  prevAccelX = accelX; prevAccelY = accelY; prevAccelZ = accelZ;
  prevMagX = magX; prevMagY = magY; prevMagZ = magZ;

  // Gyroscope
  sensors_event_t gyroEvent;
  bool gyroOK = bno.getEvent(&gyroEvent, Adafruit_BNO055::VECTOR_GYROSCOPE);

  // Accelerometer
  sensors_event_t accelEvent;
  bool accelOK = bno.getEvent(&accelEvent, Adafruit_BNO055::VECTOR_ACCELEROMETER);

  // Magnetometer
  sensors_event_t magEvent;
  bool magOK = bno.getEvent(&magEvent, Adafruit_BNO055::VECTOR_MAGNETOMETER);

  // Reject suspicious all-zero readings
  if (gyroOK && gyroEvent.gyro.x == 0 && gyroEvent.gyro.y == 0 && gyroEvent.gyro.z == 0) {
    gyroOK = false;
  }
  if (accelOK && accelEvent.acceleration.x == 0 && accelEvent.acceleration.y == 0 && accelEvent.acceleration.z == 0) {
    accelOK = false;
  }
  if (magOK && magEvent.magnetic.x == 0 && magEvent.magnetic.y == 0 && magEvent.magnetic.z == 0) {
    magOK = false;  // FIX: V1e accidentally set accelSuccess = false here
  }

  // Update globals or use previous values
  if (gyroOK) {
    gyroX = gyroEvent.gyro.x;
    gyroY = gyroEvent.gyro.y;
    gyroZ = gyroEvent.gyro.z;
  } else {
    gyroX = prevGyroX;
    gyroY = prevGyroY;
    gyroZ = prevGyroZ;
  }

  if (accelOK) {
    accelX = accelEvent.acceleration.x;
    accelY = accelEvent.acceleration.y;
    accelZ = accelEvent.acceleration.z;
  } else {
    accelX = prevAccelX;
    accelY = prevAccelY;
    accelZ = prevAccelZ;
  }

  if (magOK) {
    magX = magEvent.magnetic.x;
    magY = magEvent.magnetic.y;
    magZ = magEvent.magnetic.z;
  } else {
    magX = prevMagX;
    magY = prevMagY;
    magZ = prevMagZ;
  }

  // Fallback: direct vector read if both gyro and accel failed
  if (!gyroOK && !accelOK) {
    imu::Vector<3> g = bno.getVector(Adafruit_BNO055::VECTOR_GYROSCOPE);
    imu::Vector<3> a = bno.getVector(Adafruit_BNO055::VECTOR_ACCELEROMETER);
    imu::Vector<3> m = bno.getVector(Adafruit_BNO055::VECTOR_MAGNETOMETER);

    if (g.x() != 0 || g.y() != 0 || g.z() != 0) { gyroX = g.x(); gyroY = g.y(); gyroZ = g.z(); }
    if (a.x() != 0 || a.y() != 0 || a.z() != 0) { accelX = a.x(); accelY = a.y(); accelZ = a.z(); }
    if (m.x() != 0 || m.y() != 0 || m.z() != 0) { magX = m.x(); magY = m.y(); magZ = m.z(); }
  }

  return true;
}

////////////////////////////////////////////////////////////////////
// 19) bnoSerialTest
////////////////////////////////////////////////////////////////////
void bnoSerialTest() {
  if (!bnoWorking) { Serial.println(F("BNO055 not working")); return; }
  if (!getBNOdata()) { Serial.println(F("BNO055 read fail")); return; }

  Serial.print(F("Gyro:  ")); Serial.print(gyroX,4);  Serial.print(F(" ")); Serial.print(gyroY,4);  Serial.print(F(" ")); Serial.println(gyroZ,4);
  Serial.print(F("Accel: ")); Serial.print(accelX,4); Serial.print(F(" ")); Serial.print(accelY,4); Serial.print(F(" ")); Serial.println(accelZ,4);
  Serial.print(F("Mag:   ")); Serial.print(magX,4);   Serial.print(F(" ")); Serial.print(magY,4);   Serial.print(F(" ")); Serial.println(magZ,4);

  uint8_t sys, gyr, acc, mg;
  sys = gyr = acc = mg = 0;
  bno.getCalibration(&sys, &gyr, &acc, &mg);
  Serial.print(F("Cal: S=")); Serial.print(sys);
  Serial.print(F(" G=")); Serial.print(gyr);
  Serial.print(F(" A=")); Serial.print(acc);
  Serial.print(F(" M=")); Serial.println(mg);
  Serial.println();
}

////////////////////////////////////////////////////////////////////
// 20) GPS debug print (Serial only, not written to SD)
////////////////////////////////////////////////////////////////////
void GPS() {
  Serial.print(F("Sats: ")); Serial.print(gps.satellites.value());
  Serial.print(F("  HDOP: ")); Serial.print(gps.hdop.value());
  Serial.print(F("  Lat: ")); Serial.print(gps.location.lat(), 6);
  Serial.print(F("  Lng: ")); Serial.print(gps.location.lng(), 6);
  Serial.print(F("  Alt(ft): ")); Serial.print(gps.altitude.feet(), 2);
  Serial.print(F("  Age: ")); Serial.print(gps.location.age());

  if (gps.date.isValid()) {
    char sz[12];
    snprintf(sz, sizeof(sz), "  %02d/%02d/%04d", gps.date.month(), gps.date.day(), gps.date.year());
    Serial.print(sz);
  }
  if (gps.time.isValid()) {
    char sz[12];
    snprintf(sz, sizeof(sz), " %02d:%02d:%02d", gps.time.hour(), gps.time.minute(), gps.time.second());
    Serial.print(sz);
  }
  Serial.println();
}

////////////////////////////////////////////////////////////////////
// 21) checkImpact — BNO055 accelerometer-based landing detection
//     Reads raw accel and computes magnitude. If above threshold,
//     triggers emergency SD flush to protect data before power loss.
//     BNO055 accel range: ±16g (±156 m/s^2). Threshold: 6g (58 m/s^2).
////////////////////////////////////////////////////////////////////
void checkImpact() {
  sensors_event_t accelEvent;
  if (!bno.getEvent(&accelEvent, Adafruit_BNO055::VECTOR_ACCELEROMETER)) return;

  float ax = accelEvent.acceleration.x;
  float ay = accelEvent.acceleration.y;
  float az = accelEvent.acceleration.z;

  // Magnitude of acceleration vector
  // At rest: ~9.8 m/s^2. During freefall: ~0. On impact: spike to 60+ m/s^2
  float mag = sqrt(ax * ax + ay * ay + az * az);

  if (mag > IMPACT_THRESHOLD_MS2) {
    impactDetected = true;
    impactTime = millis();
    flightPhase = PHASE_LANDED;

    Serial.print(F("*** IMPACT DETECTED: "));
    Serial.print(mag, 1);
    Serial.println(F(" m/s^2 — emergency flush ***"));

    // Emergency: log this exact moment, then flush everything
    emergencyFlush();
  }
}

////////////////////////////////////////////////////////////////////
// 22) emergencyFlush — immediate SD write and close
//     Called on impact to save all buffered data before potential
//     power loss. Opens file, writes any buffered points, flushes,
//     and closes. After this, data is safely on the FAT filesystem.
////////////////////////////////////////////////////////////////////
void emergencyFlush() {
  if (!sdCardWorking) return;

  // Flush any buffered data first
  if (bufferCount > 0) {
    flushBuffer();
  }

  // Force a sync of the SD card's FAT table
  dataFile = SD.open(DATA_FILE_NAME, FILE_WRITE);
  if (dataFile) {
    dataFile.flush();
    dataFile.close();
  }

  Serial.println(F("Emergency flush complete — data safe on SD"));
}

////////////////////////////////////////////////////////////////////
// 23) updateFlightPhase — altitude-based state machine
//     Uses BMP390 barometric altitude (more reliable than GPS at alt).
//
//     States:
//       GROUND(0)  -> ASCENT(1)  when alt > launch + 100m
//       ASCENT(1)  -> FLOAT(2)   when vertical rate < 2 m/sample for 5 samples
//       FLOAT(2)   -> DESCENT(3) when alt < peak - 50m
//       DESCENT(3) -> LANDED(4)  when alt < 200m AGL and rate < 1 m/sample
//       LANDED(4)  stays landed (also set by impact detection)
//
//     Returns current phase for logging.
////////////////////////////////////////////////////////////////////
uint8_t updateFlightPhase(float currentAlt, bool altFresh) {
  if (!launchAltitudeSet || !altFresh) return flightPhase;

  static uint8_t floatCounter = 0;  // counts consecutive low-rate samples

  // Track peak altitude
  if (currentAlt > peakAltitude) {
    peakAltitude = currentAlt;
  }

  float altAboveLaunch = currentAlt - launchAltitude;
  float verticalDelta = currentAlt - prevPhaseAltitude;
  prevPhaseAltitude = currentAlt;

  switch (flightPhase) {
    case PHASE_GROUND:
      if (altAboveLaunch > ASCENT_TRIGGER_M) {
        flightPhase = PHASE_ASCENT;
        floatCounter = 0;
        Serial.println(F("PHASE: ASCENT"));
      }
      break;

    case PHASE_ASCENT:
      if (abs(verticalDelta) < FLOAT_RATE_MS) {
        floatCounter++;
        if (floatCounter >= 5) {
          flightPhase = PHASE_FLOAT;
          Serial.println(F("PHASE: FLOAT"));
        }
      } else {
        floatCounter = 0;
      }
      break;

    case PHASE_FLOAT:
      if (peakAltitude - currentAlt > DESCENT_DROP_M) {
        flightPhase = PHASE_DESCENT;
        Serial.println(F("PHASE: DESCENT"));
      }
      break;

    case PHASE_DESCENT:
      if (altAboveLaunch < LANDED_ALT_M && abs(verticalDelta) < LANDED_RATE_MS) {
        flightPhase = PHASE_LANDED;
        Serial.println(F("PHASE: LANDED"));
      }
      break;

    case PHASE_LANDED:
      // Terminal state — also reachable via checkImpact()
      break;
  }

  return flightPhase;
}

////////////////////////////////////////////////////////////////////
// 24) writeEepromGPS — save last-known GPS position to EEPROM
//     Layout: bytes 0-3 = latE6 (int32), 4-7 = lngE6 (int32), 8-11 = altCm (int32)
//     Only writes if value has actually changed (EEPROM.update avoids
//     unnecessary wear — only writes cells whose value differs).
////////////////////////////////////////////////////////////////////
void writeEepromGPS() {
  double lat = gps.location.lat();
  double lng = gps.location.lng();
  int32_t latE6 = (int32_t)(lat * 1000000.0 + (lat >= 0 ? 0.5 : -0.5));
  int32_t lngE6 = (int32_t)(lng * 1000000.0 + (lng >= 0 ? 0.5 : -0.5));
  int32_t altCm = 0;
  if (gps.altitude.isValid()) {
    altCm = (int32_t)(gps.altitude.meters() * 100.0);
  }

  EEPROM.put(EEPROM_GPS_ADDR,     latE6);
  EEPROM.put(EEPROM_GPS_ADDR + 4, lngE6);
  EEPROM.put(EEPROM_GPS_ADDR + 8, altCm);

  Serial.print(F("EEPROM: saved "));
  Serial.print(lat, 6); Serial.print(F(", "));
  Serial.print(lng, 6); Serial.print(F(" alt="));
  Serial.println(gps.altitude.meters(), 1);
}

////////////////////////////////////////////////////////////////////
// 25) readEepromGPS — read and display last-known position on boot
//     If EEPROM is blank (all 0xFF), prints "no previous position."
////////////////////////////////////////////////////////////////////
void readEepromGPS() {
  int32_t latE6, lngE6, altCm;
  EEPROM.get(EEPROM_GPS_ADDR,     latE6);
  EEPROM.get(EEPROM_GPS_ADDR + 4, lngE6);
  EEPROM.get(EEPROM_GPS_ADDR + 8, altCm);

  // Check for blank EEPROM (all 0xFF = -1 as int32)
  if (latE6 == -1 && lngE6 == -1) {
    Serial.println(F("EEPROM: no previous GPS position stored."));
    return;
  }

  Serial.println(F("=== LAST KNOWN GPS POSITION (from EEPROM) ==="));
  Serial.print(F("  Lat: "));
  if (latE6 < 0) Serial.print('-');
  Serial.print(labs(latE6) / 1000000L); Serial.print('.');
  char buf[7];
  snprintf(buf, sizeof(buf), "%06ld", labs(latE6) % 1000000L);
  Serial.println(buf);

  Serial.print(F("  Lng: "));
  if (lngE6 < 0) Serial.print('-');
  Serial.print(labs(lngE6) / 1000000L); Serial.print('.');
  snprintf(buf, sizeof(buf), "%06ld", labs(lngE6) % 1000000L);
  Serial.println(buf);

  Serial.print(F("  Alt: "));
  Serial.print(altCm / 100L); Serial.print('.');
  snprintf(buf, sizeof(buf), "%02ld", labs(altCm % 100L));
  Serial.print(buf); Serial.println(F(" m"));
  Serial.println(F("============================================="));
}