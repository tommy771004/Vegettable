package com.vegettable.app.model

import com.google.gson.annotations.SerializedName

class CreateAlertRequest(
    @field:SerializedName("deviceToken") private val deviceToken: String?,
    @field:SerializedName(
        "cropName"
    ) private val cropName: String?,
    @field:SerializedName("targetPrice") private val targetPrice: Double,
    @field:SerializedName(
        "condition"
    ) private val condition: String?
)
