package com.vegettable.app.model

/** 農業氣象觀測資料 */
data class WeatherObservation(
    val stationId: String,
    val stationName: String,
    val county: String,
    val township: String,
    val obsTime: String,
    val temperature: Double?,
    val relHumidity: Double?,
    val rainfall: Double?,
    val windSpeed: Double?,
    val windDirection: String?,
    val sunshineHours: Double?,
    val solarRadiation: Double?,
    val latitude: Double?,
    val longitude: Double?,
    val weatherSummary: String
)
