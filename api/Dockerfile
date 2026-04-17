# 1. 建立編譯環境 (使用 SDK)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# 先只複製 csproj 並還原相依套件 (利用 Docker 快取機制加速下次建置)
# 支援從上層目錄建置，因此路徑使用 "VegettableApi/VegettableApi.csproj"
COPY ["VegettableApi/VegettableApi.csproj", "VegettableApi/"]
RUN dotnet restore "VegettableApi/VegettableApi.csproj"

# 複製所有原始碼並編譯（從 build context 複製整個 repo）
COPY . .
WORKDIR "/src/VegettableApi"
RUN dotnet publish "VegettableApi.csproj" -c Release -o /app/publish /p:UseAppHost=false

# 2. 建立執行環境 (使用較小的 ASP.NET 執行時期)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

# 預設對外 Port 為 8080 (ASP.NET Core 8 預設行為)
EXPOSE 8080

# 將編譯好的檔案複製過來
COPY --from=build /app/publish .

# 設定容器啟動時執行的指令
ENTRYPOINT ["dotnet", "VegettableApi.dll"]
