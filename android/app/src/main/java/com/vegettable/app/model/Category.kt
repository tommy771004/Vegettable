package com.vegettable.app.model

data class Category(
    val key: String,
    val label: String,
    val icon: String,
    val subCategories: List<SubCategory>?
)

data class SubCategory(
    val key: String,
    val label: String,
    val icon: String
)
