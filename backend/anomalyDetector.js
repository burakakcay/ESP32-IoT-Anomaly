function calculateMean(values) {
	if (values.length === 0) {
		return 0;
	}

	return values.reduce((sum, value) => sum + value, 0) / values.length;
}

function calculateStandardDeviation(values, mean) {
	if (values.length === 0) {
		return 0;
	}

	const variance =
		values.reduce((sum, value) => sum + Math.pow(value - mean, 2), 0) /
		values.length;

	return Math.sqrt(variance);
}

function calculateZScore(value, mean, standardDeviation) {
	if (standardDeviation === 0) {
		return 0;
	}

	return (value - mean) / standardDeviation;
}

function detectAnomaly(values, threshold = 3) {
	const mean = calculateMean(values);
	const standardDeviation = calculateStandardDeviation(values, mean);

	const latestValue = values[values.length - 1];

	const zScore = calculateZScore(latestValue, mean, standardDeviation);

	return {
		value: latestValue,
		mean,
		standardDeviation,
		zScore,
		isAnomaly: Math.abs(zScore) >= threshold,
	};
}

module.exports = {
	calculateMean,
	calculateStandardDeviation,
	calculateZScore,
	detectAnomaly,
};
