package com.vegettable.app.model

import com.google.gson.annotations.SerializedName

/**
 * .NET API 統一回應格式
 */
class ApiResponse<T> {
    @SerializedName("success")
    val isSuccess: Boolean = false

    @JvmField
    @SerializedName("data")
    val data: T? = null

    @SerializedName("message")
    val message: String? = null

    @SerializedName("timestamp")
    val timestamp: Long = 0
}
