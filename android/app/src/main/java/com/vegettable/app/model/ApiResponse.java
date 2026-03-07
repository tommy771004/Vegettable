package com.vegettable.app.model;

import com.google.gson.annotations.SerializedName;

/**
 * .NET API 統一回應格式
 */
public class ApiResponse<T> {
    @SerializedName("success")
    private boolean success;

    @SerializedName("data")
    private T data;

    @SerializedName("message")
    private String message;

    @SerializedName("timestamp")
    private long timestamp;

    public boolean isSuccess() { return success; }
    public T getData() { return data; }
    public String getMessage() { return message; }
    public long getTimestamp() { return timestamp; }
}
