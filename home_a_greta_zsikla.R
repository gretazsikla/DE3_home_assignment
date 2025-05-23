packages <- c("httr", "jsonlite", "dplyr", "lubridate", "Microsoft365R")
new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)

library(httr)
library(jsonlite)
library(dplyr)
library(lubridate)
library(Microsoft365R)

# 1. Get past hour timestamp in milliseconds
end_time <- now(tz = "UTC")
start_time <- end_time - hours(1)

# 2. Binance API call
url <- "https://api.binance.com/api/v3/klines"
params <- list(
  symbol = "ETHUSDT",
  interval = "1m",
  startTime = as.numeric(as.POSIXct(start_time)) * 1000,
  endTime = as.numeric(as.POSIXct(end_time)) * 1000
)

res <- GET(url, query = params)
data <- fromJSON(content(res, "text", encoding = "UTF-8"))

# 3. Extract and format prices
eth_data <- data.frame(
  time = as.POSIXct(sapply(data, `[[`, 1)/1000, origin = "1970-01-01", tz = "UTC"),
  open = as.numeric(sapply(data, `[[`, 2)),
  high = as.numeric(sapply(data, `[[`, 3)),
  low = as.numeric(sapply(data, `[[`, 4)),
  close = as.numeric(sapply(data, `[[`, 5))
)

min_price <- min(eth_data$low)
max_price <- max(eth_data$high)

# 4. Send message to MS Teams via Incoming Webhook
webhook_url <- Sys.getenv("TEAMS_WEBHOOK")  # Set in Jenkins or .Renviron
username <- "ETH Bot"
emoji <- ":robot_face:"

msg <- sprintf("Hourly ETH Summary:\nMin: $%.2f\nMax: $%.2f", min_price, max_price)

body <- list(
  text = msg,
  username = username,
  icon_emoji = emoji
)

# Using Microsoft365R to send to a Teams channel
teams <- get_team("Your Team Name")
channel <- teams$get_channel("bots-bots-bots")
channel$send_message(msg)
