require 'httparty'

url = 'https://api.betfair.com/exchange/betting/rest/v1.0/listEventTypes/'
headers = { 'X-Application': 'XmjKUoJFJ2F8Gk0y', 'X-Authentication': 'r2QQim2V+qedVrwevWL8iBT7IorrQC7Xp9nV0dsVweY' ,'content-type': 'application/json' }
response = HTTParty.post(url, headers: headers)
puts response.body
