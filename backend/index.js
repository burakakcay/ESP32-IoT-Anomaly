require("dotenv").config();

const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const express = require("express");
const OpenAI = require("openai");

const serviceAccount = require("./serviceAccountKey.json");

initializeApp({
	credential: cert(serviceAccount),
});

const db = getFirestore();
const app = express();
const PORT = 3000;

app.use(express.json());

const DEVICE_ID = "ESP32_Sensor_Node_001";
const READING_LIMIT = 60;
const MIN_BASELINE_SIZE = 20;

let anomalyCache = null;
let anomalyCacheTime = 0;

const ANOMALY_CACHE_DURATION = 10000; // 10 saniye

const openai = new OpenAI({
	apiKey: process.env.OPENAI_API_KEY,
});

// --------------------------------------------------
// Firestore'dan son ölçümleri alma
// --------------------------------------------------

async function getReadings(limit = READING_LIMIT) {
	const snapshot = await db
		.collection("devices")
		.doc(DEVICE_ID)
		.collection("readings")
		.orderBy("timestamp", "desc")
		.limit(limit)
		.get();

	return snapshot.docs.map((doc) => ({
		id: doc.id,
		...doc.data(),
	}));
}

// --------------------------------------------------
// Ortalama
// --------------------------------------------------

function calculateMean(values) {
	if (values.length === 0) {
		return 0;
	}

	return values.reduce((sum, value) => sum + value, 0) / values.length;
}

// --------------------------------------------------
// Standart sapma
// --------------------------------------------------

function calculateStandardDeviation(values, mean) {
	if (values.length === 0) {
		return 0;
	}

	const variance =
		values.reduce((sum, value) => {
			return sum + Math.pow(value - mean, 2);
		}, 0) / values.length;

	return Math.sqrt(variance);
}

// --------------------------------------------------
// Z-score
// --------------------------------------------------

function calculateZScore(value, mean, standardDeviation) {
	if (standardDeviation === 0) {
		return 0;
	}

	return (value - mean) / standardDeviation;
}

// --------------------------------------------------
// Median
// --------------------------------------------------

function calculateMedian(values) {
	if (values.length === 0) {
		return 0;
	}

	const sorted = [...values].sort((a, b) => a - b);

	const middle = Math.floor(sorted.length / 2);

	if (sorted.length % 2 === 0) {
		return (sorted[middle - 1] + sorted[middle]) / 2;
	}

	return sorted[middle];
}

// --------------------------------------------------
// MAD (Median Absolute Deviation)
// --------------------------------------------------

function calculateMAD(values, median) {
	if (values.length === 0) {
		return 0;
	}

	const deviations = values.map((value) => Math.abs(value - median));

	return calculateMedian(deviations);
}

// --------------------------------------------------
// Robust Z-score
// --------------------------------------------------

function calculateRobustZScore(value, median, mad) {
	if (mad === 0) {
		return 0;
	}

	return (0.6745 * (value - median)) / mad;
}

// --------------------------------------------------
// /api/readings
// --------------------------------------------------

app.get("/api/readings", async (req, res) => {
	try {
		const readings = await getReadings();

		res.json(readings);
	} catch (error) {
		console.error("Firestore okuma hatası:", error);

		res.status(500).json({
			error: "Sensör verileri alınamadı.",
		});
	}
});

// --------------------------------------------------
// /api/anomalies
// --------------------------------------------------

app.get("/api/anomalies", async (req, res) => {
	try {
		// Cache hâlâ geçerliyse Firestore'a gitme
		if (
			anomalyCache !== null &&
			Date.now() - anomalyCacheTime < ANOMALY_CACHE_DURATION
		) {
			console.log("Anomaly cache kullanıldı.");

			return res.json(anomalyCache);
		}

		console.log("Anomaly cache süresi doldu. Firestore okunuyor...");

		const readings = await getReadings();

		if (readings.length < MIN_BASELINE_SIZE + 1) {
			return res.status(400).json({
				error: `Anomali analizi için en az ${
					MIN_BASELINE_SIZE + 1
				} ölçüm gerekli.`,
			});
		}

		// Firestore verileri en yeniden eskiye geliyor.
		// Analiz için eski -> yeni sıralıyoruz.
		const chronologicalReadings = [...readings].reverse();

		const fields = [
			"accel_x",
			"accel_y",
			"accel_z",
			"gyro_x",
			"gyro_y",
			"gyro_z",
			"temperature",
			"humidity",
		];

		const results = [];

		let anomalyCount = 0;

		for (let i = MIN_BASELINE_SIZE; i < chronologicalReadings.length; i++) {
			const currentReading = chronologicalReadings[i];

			// Sadece geçmiş ölçümler baseline.
			const baselineReadings = chronologicalReadings.slice(0, i);

			const measurements = {};

			let readingAnomalyCount = 0;

			for (const field of fields) {
				const values = baselineReadings
					.map((reading) => Number(reading[field]))
					.filter((value) => Number.isFinite(value));

				const currentValue = Number(currentReading[field]);

				if (
					values.length < MIN_BASELINE_SIZE ||
					!Number.isFinite(currentValue)
				) {
					measurements[field] = {
						value: currentReading[field],
						median: null,
						mad: null,
						robustZScore: null,
						isAnomaly: false,
					};

					continue;
				}

				const median = calculateMedian(values);

				const mad = calculateMAD(values, median);

				const robustZScore = calculateRobustZScore(currentValue, median, mad);

				const isAnomaly = Math.abs(robustZScore) > 5;

				if (isAnomaly) {
					readingAnomalyCount++;
				}

				measurements[field] = {
					value: currentValue,
					median: Number(median.toFixed(2)),
					mad: Number(mad.toFixed(2)),
					robustZScore: Number(robustZScore.toFixed(2)),
					isAnomaly,
				};
			}

			const isReadingAnomaly = readingAnomalyCount > 0;

			if (isReadingAnomaly) {
				anomalyCount++;
			}

			results.push({
				timestamp: currentReading.timestamp,
				anomalyCount: readingAnomalyCount,
				isAnomaly: isReadingAnomaly,
				measurements,
			});
		}

		const anomalyResults = results
			.filter((result) => result.isAnomaly === true)
			.map((result) => {
				const anomalyMeasurements = {};

				for (const [field, measurement] of Object.entries(
					result.measurements,
				)) {
					if (measurement.isAnomaly === true) {
						anomalyMeasurements[field] = measurement;
					}
				}

				return {
					timestamp: result.timestamp,
					anomalyCount: result.anomalyCount,
					isAnomaly: result.isAnomaly,
					measurements: anomalyMeasurements,
				};
			});
		const response = {
			device_id: DEVICE_ID,
			analyzedReadings: results.length,
			anomalyReadings: anomalyCount,
			results: anomalyResults,
		};

		anomalyCache = response;
		anomalyCacheTime = Date.now();

		res.json(response);
	} catch (error) {
		console.error("Anomali analizi hatası:", error);
		res.status(500).json({
			error: "Anomali analizi yapılamadı.",
		});
	}
});

// --------------------------------------------------
// Server
// --------------------------------------------------
app.listen(PORT, () => {
	console.log("=============================================");
	console.log("BACKEND BAŞLADI");
	console.log("READINGS : http://localhost:3000/api/readings");
	console.log("ANOMALIES: http://localhost:3000/api/anomalies");
	console.log("=============================================");
});

async function analyzeAnomaliesWithAI(anomalyResults) {
	if (!anomalyResults || anomalyResults.length === 0) {
		return {
			summary: "Son ölçümlerde anomali tespit edilmedi.",
			severity: "normal",
			possibleCause: null,
			affectedSensors: [],
		};
	}

	const prompt = `
Sen Sentinel isimli bir IoT sensör izleme sisteminin
anomali analiz asistanısın.

Aşağıdaki veriler ESP32 üzerinde bulunan DHT22 ve MPU6050
sensörlerinden alınmıştır.

DHT22:
- temperature
- humidity

MPU6050:
- accel_x
- accel_y
- accel_z
- gyro_x
- gyro_y
- gyro_z

Anomaliler Robust Z-score yöntemiyle tespit edilmiştir.

Görevin:
1. Anomalilerin genel durumunu değerlendir.
2. Hangi sensörlerin etkilendiğini belirle.
3. Olası nedeni tahmin et.
4. Ciddiyet seviyesini belirle.
5. Kısa ve anlaşılır bir açıklama üret.

Önemli:
- Veride olmayan bilgileri uydurma.
- Kesin teşhis koyma.
- Olası nedenleri "muhtemel" olarak ifade et.
- Özellikle ivme ve jiroskop değerlerinin birlikte değişmesini
  fiziksel hareket açısından değerlendir.
- Sıcaklık ve nem anomalilerini fiziksel hareketten ayrı değerlendir.

Anomali verileri:

${JSON.stringify(anomalyResults, null, 2)}

Cevabı yalnızca aşağıdaki JSON formatında üret:

{
  "summary": "kısa açıklama",
  "severity": "low | medium | high | critical",
  "possibleCause": "olası neden",
  "affectedSensors": ["gyro_y", "gyro_z"]
}
`;

	const response = await openai.responses.create({
		model: "gpt-5-mini",
		input: prompt,
	});

	return JSON.parse(response.output_text);
}

app.get("/api/anomalies/ai", async (req, res) => {
	try {
		const readings = await getReadings();

		if (readings.length < MIN_BASELINE_SIZE + 1) {
			return res.status(400).json({
				error: "AI analizi için yeterli veri yok.",
			});
		}

		// Burada mevcut anomaly hesaplama mantığımızı kullanıyoruz.
		const chronologicalReadings = [...readings].reverse();

		const fields = [
			"accel_x",
			"accel_y",
			"accel_z",
			"gyro_x",
			"gyro_y",
			"gyro_z",
			"temperature",
			"humidity",
		];

		const results = [];

		for (let i = MIN_BASELINE_SIZE; i < chronologicalReadings.length; i++) {
			const currentReading = chronologicalReadings[i];

			const baselineReadings = chronologicalReadings.slice(0, i);

			const measurements = {};

			let readingAnomalyCount = 0;

			for (const field of fields) {
				const values = baselineReadings
					.map((reading) => Number(reading[field]))
					.filter((value) => Number.isFinite(value));

				const currentValue = Number(currentReading[field]);

				if (
					values.length < MIN_BASELINE_SIZE ||
					!Number.isFinite(currentValue)
				) {
					continue;
				}

				const median = calculateMedian(values);
				const mad = calculateMAD(values, median);

				const robustZScore = calculateRobustZScore(currentValue, median, mad);

				const isAnomaly = Math.abs(robustZScore) > 5;

				if (isAnomaly) {
					readingAnomalyCount++;
				}

				measurements[field] = {
					value: currentValue,
					median: Number(median.toFixed(2)),
					mad: Number(mad.toFixed(2)),
					robustZScore: Number(robustZScore.toFixed(2)),
					isAnomaly,
				};
			}

			if (readingAnomalyCount > 0) {
				results.push({
					timestamp: currentReading.timestamp,
					anomalyCount: readingAnomalyCount,
					measurements,
				});
			}
		}

		// Son anomalileri AI'a gönderiyoruz.
		const recentAnomalies = results.slice(-10);

		const aiAnalysis = await analyzeAnomaliesWithAI(recentAnomalies);

		res.json({
			device_id: DEVICE_ID,
			analyzedReadings: chronologicalReadings.length - MIN_BASELINE_SIZE,
			anomalyReadings: results.length,
			anomalies: recentAnomalies,
			aiAnalysis,
		});
	} catch (error) {
		console.error("AI anomaly analizi hatası:", error);

		res.status(500).json({
			error: "AI anomali analizi yapılamadı.",
		});
	}
});
