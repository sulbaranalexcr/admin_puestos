require_relative 'config/environment'
# create a client with app code
require 'betfair'
client = Betfair::Client.new("X-Application" => "XmjKUoJFJ2F8Gk0y")

# let's log in.
client.interactive_login("sulbaranalex@gmail.com", "Ajss271127.")

# you can do stuff like list event types:
event_types = client.list_event_types(filter: {})
# =>  [
#       {
#         "eventType"=>{
#           "id"=>"7",
#           "name"=>"Horse Racing"
#         },
#         "marketCount"=>215
#       },
#       ..etc..
#     ]

# todays GB & Ireland horse racing win & place markets
# pp "*******************"
# pp client.get_account_funds()
# pp "*******************fin"
# pp client.list_current_orders()
# pp "*******************fin2"
# pp client.list_market_book()
# pp "*******************fin3"
# pp client.list_event_types()
# pp "*******************fin4"
# pp client.list_market_catalogue()
# pp "*******************fin5111"
# pp client.list_events({
#   filter: {
#     marketTypeCodes: ["raceStatus"],
#     raceId: 924.288621042
# }})
# pp "*******************fin5"
racing_markets = client.list_market_catalogue({
  filter: {
    eventTypeIds: [7],
    marketTypeCodes: ["WIN"],
    marketStartTime: {
      from: Time.now.beginning_of_day.iso8601,
      to: Time.now.end_of_day.iso8601
    },
    marketCountries: ["US"]
  },
  maxResults: 200,
  marketStatus: [ "INACTIVE", "OPEN", "SUSPENDED", "CLOSED"],
  marketProjection: [
    "MARKET_START_TIME",
    "RUNNER_METADATA",
    "RUNNER_DESCRIPTION",
    "MARKET_DESCRIPTION",
    "EVENT_TYPE",
    "EVENT",
    "COMPETITION"
  ]

})
# racing_markets.each do |rac|
#   puts rac['event']['name']
#   puts rac['marketName']
# end
# pp racing_markets.first
while true
 pp racing_markets.first['marketName']
consulta = client.list_market_book({
      marketIds: [racing_markets.first['marketId']]
      #  priceProjection: { priceData: ["EX_BEST_OFFERS"]},
      #  exBestOfferOverRides: { bestPricesDepth:2,
      #                          rollupModel: "STAKE",
      #                          rollupLimit: 20 },
      #  virtualise: false,
      #  rolloverStakes: false ,
      #  orderProjection: "ALL",
      #  matchProjection: "ROLLED_UP_BY_PRICE"

})
pp consulta.first['status']
# pp consulta
sleep 1
end
 byebug
# pp "*******************fin6"
# pp racing_markets.class
# pp racing_markets[0]

# byebug
# racing_et_id = event_types.find{|et| et["eventType"]["name"] == "Horse Racing"}["eventType"]["id"]
# puts "***********************"
# racing_markets = client.list_market_catalogue({
#   filter: {
#     eventTypeIds: [racing_et_id],
#     marketTypeCodes: ["WIN", "PLACE"],
#     marketStartTime: {
#       from: Time.now.beginning_of_day.iso8601,
#       to: Time.now.end_of_day.iso8601
#     },
#     marketCountries: ["GB", "IRE"]
#   },
#   maxResults: 200,
#   marketProjection: [
#     "MARKET_START_TIME",
#     "RUNNER_METADATA",
#     "RUNNER_DESCRIPTION",
#     "EVENT_TYPE",
#     "EVENT",
#     "COMPETITION"
#   ]
# })

# given an eventId from the market catalogue (the first for example),
# let's have a flutter shall we?
market = racing_markets.first
market_id = market["marketId"]
selection_id = market["runners"].find { |r| r["runnerName"] == "Lady Frosted" }["selectionId"]

# this places an Betfair SP bet with a price limit of 3.0 .
# see the API docs for the different types of orders.
pp client.methods
# log back out.
client.logout
