URL = url = "https://api.betfair.com/exchange/betting/json-rpc/v1"
sessionToken = "etKe60FBmp81kjeiE/PJTEVJ0y76R59UV+pqXMahROo="
appKey = "XmjKUoJFJ2F8Gk0y"
jsonrpc_req = '{"jsonrpc": "2.0", "method": "SportsAPING/v1.0/listEventTypes", "params": {"filter":{ }}, "id": 1}'
headers = {'X-Application': appKey, 'X-Authentication': sessionToken, 'content-type': 'application/json'}
 
def callAping(jsonrpc_req):
    try:
        req = urllib2.Request(url, jsonrpc_req, headers)
        response = urllib2.urlopen(req)
        jsonResponse = response.read()
        return jsonResponse
    except urllib2.URLError:
        print 'Oops no service available at ' + str(url)
        exit()
    except urllib2.HTTPError:
        print 'Oops not a valid operation from the service ' + str(url)
        exit()

def getMarketBook(marketId):
    if( marketId is not None):
        print 'Calling listMarketBook to read prices for the Market with ID :' + marketId
        market_book_req = '{"marketIds":["' + marketId + '"],"priceProjection":{"priceData":["EX_BEST_OFFERS"]}}'
 
        endPoint = 'https://api.betfair.com/rest/v1.0/listMarketBook/'
 
        market_book_response = callAping(endPoint)
        market_book_loads = json.loads(market_book_response)
        return market_book_loads
 
 
def printPriceInfo(market_book_result):
    print 'Please find Best three available prices for the runners'
    for marketBook in market_book_result:
        try:
            runners = marketBook['runners']
            for runner in runners:
                print 'Selection id is ' + str(runner['selectionId'])
                if (runner['status'] == 'ACTIVE'):
                    print 'Available to back price :' + str(runner['ex']['availableToBack'])
                    print 'Available to lay price :' + str(runner['ex']['availableToLay'])
                else:
                    print 'This runner is not active'
        except:
            print 'No runners available for this market'
 
market_book_result = getMarketBook('7')
printPriceInfo(market_book_result)
