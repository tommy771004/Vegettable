package com.vegettable.app.model

data class FeedbackRequest(
    val feedbackType: String,   // "bug" | "suggestion" | "other"
    val content: String,
    val deviceToken: String?,
    val platform: String = "android",
    val appVersion: String? = null
)

data class FeedbackResult(
    val id: Int,
    val message: String,
    val createdAt: String
)
