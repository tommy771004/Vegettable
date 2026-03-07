package com.vegettable.app.model;

import com.google.gson.annotations.SerializedName;
import java.util.List;

public class Recipe {
    @SerializedName("name")
    private String name;

    @SerializedName("description")
    private String description;

    @SerializedName("ingredients")
    private List<String> ingredients;

    @SerializedName("difficulty")
    private String difficulty; // "easy" | "medium" | "hard"

    @SerializedName("cookTimeMinutes")
    private int cookTimeMinutes;

    public String getName() { return name; }
    public String getDescription() { return description; }
    public List<String> getIngredients() { return ingredients; }
    public String getDifficulty() { return difficulty; }
    public int getCookTimeMinutes() { return cookTimeMinutes; }
}
