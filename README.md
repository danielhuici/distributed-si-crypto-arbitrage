# Software Infraestructuture for multistrategic arbitrage of Cryptocurrency

An Elixir implementation of a cryptocurrency arbitrage software. It scrappes coin values from several exchanges and calculates the possible profit by using several strategies. 

- Distributed: the implementation is completly modular, so every module of the system can be deployed on different nodes. It's a fault tolerant, master-worker infraestructure which makes the system more reliable and easier to deploy.
- Multistrategic: the system supports the scrapping of different exchanges, and the calculation of possible profits with more strategies.
- SI Good practices: the architecture has been designed carefully, so it makes adding a new exchange/coin/calculation strategy really easy.
- Abstract View: API Rest is available to obtain data, so it makes client integration easier.

## Currently supported exchanges
- Binance
- Bitfinex

## Currently supported strategies
- Triangular strategy

## Output example
You can retrive the data at `localhost:8080/values`
````
{"ADA_BTC":{"max_exchange":"binance","max_value":2.384e-5,"min_exchange":"bitfinex","min_value":2.383e-5,"profit":1.000419639110365},"BTC_USD":{"max_exchange":"bitfinex","max_value":55477.68174907559,"min_exchange":"binance","min_value":55318.33063802,"profit":1.0028806203878118},"ETH_BTC":{"max_exchange":"bitfinex","max_value":0.048626236518810984,"min_exchange":"binance","min_value":0.04850996,"profit":1.00239696175406},"LTC_BTC":{"max_exchange":"bitfinex","max_value":0.004766598599575341,"min_exchange":"binance","min_value":0.00475406,"profit":1.0026374508473475}}
````

## How to deploy

For now, the deploy only supports Windows. It will support Linux in the future.
Elixir must be installed on your machine.

```` 
web-server\run.bat
main-app\run.bat
````

