package com.vegettable.app.model

import com.google.gson.annotations.SerializedName

class Recipe {
    @JvmField
    @SerializedName("name")
    val name: String? = null

    @JvmField
    @SerializedName("description")
    val description: String? = null

    @SerializedName("ingredients")
    val ingredients: MutableList<String?>? = null

    @SerializedName("difficulty")
    val difficulty: String? = null // "easy" | "medium" | "hard"

    @JvmField
    @SerializedName("cookTimeMinutes")
    val cookTimeMinutes: Int = 0
}
