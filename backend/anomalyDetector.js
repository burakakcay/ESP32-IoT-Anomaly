const FIELDS = [
	"accel_x",
	"accel_y",
	"accel_z",
	"gyro_x",
	"gyro_y",
	"gyro_z",
	"temperature",
	"humidity",
];

function calculateMedian(values) {
	if (values.length === 0) return 0;

	const sorted = [...values].sort((a, b) => a - b);
	const middle = Math.floor(sorted.length / 2);

	return sorted.length % 2 === 0
		? (sorted[middle - 1] + sorted[middle]) / 2
		: sorted[middle];
}

function calculateMAD(values, median) {
	if (values.length === 0) return 0;

	return calculateMedian(values.map((value) => Math.abs(value - median)));
}

function calculateRobustZScore(value, median, mad) {
	if (mad === 0) return 0;

	return (0.6745 * (value - median)) / mad;
}

function calculateAnomalyResults(readings, minBaselineSize) {
	const chronologicalReadings = [...readings].reverse();
	const results = [];
	let anomalyCount = 0;

	for (let i = minBaselineSize; i < chronologicalReadings.length; i++) {
		const currentReading = chronologicalReadings[i];
		const baselineReadings = chronologicalReadings.slice(0, i);
		const measurements = {};
		let readingAnomalyCount = 0;

		for (const field of FIELDS) {
			const values = baselineReadings
				.map((reading) => Number(reading[field]))
				.filter((value) => Number.isFinite(value));
			const currentValue = Number(currentReading[field]);

			if (values.length < minBaselineSize || !Number.isFinite(currentValue)) {
				measurements[field] = {
					value: currentReading[field], median: null, mad: null,
					robustZScore: null, isAnomaly: false,
				};
				continue;
			}

			const median = calculateMedian(values);
			const mad = calculateMAD(values, median);
			const robustZScore = calculateRobustZScore(currentValue, median, mad);
			const isAnomaly = Math.abs(robustZScore) > 5;

			if (isAnomaly) readingAnomalyCount++;

			measurements[field] = {
				value: currentValue,
				median: Number(median.toFixed(2)),
				mad: Number(mad.toFixed(2)),
				robustZScore: Number(robustZScore.toFixed(2)),
				isAnomaly,
			};
		}

		const isAnomaly = readingAnomalyCount > 0;
		if (isAnomaly) anomalyCount++;
		results.push({ timestamp: currentReading.timestamp, anomalyCount: readingAnomalyCount, isAnomaly, measurements });
	}

	const anomalyResults = results
		.filter((result) => result.isAnomaly)
		.map((result) => ({
			timestamp: result.timestamp,
			anomalyCount: result.anomalyCount,
			isAnomaly: result.isAnomaly,
			measurements: Object.fromEntries(
				Object.entries(result.measurements).filter(([, measurement]) => measurement.isAnomaly),
			),
		}));

	return { analyzedReadings: results.length, anomalyReadings: anomalyCount, results: anomalyResults };
}

module.exports = { calculateAnomalyResults };
