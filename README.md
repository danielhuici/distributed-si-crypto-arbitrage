# Software Infraestructuture for multistrategic arbitrage of Cryptocurrency

An Elixir implementation of a cryptocurrency arbitrage software. It scrappes coin values from several exchanges and calculates the possible profit by using several strategies. 

- Distributed: the implementation is completly modular, so every module of the system can be deployed on different nodes. It's a fault tolerant, master-worker infraestructure which makes the system more reliable and easier to deploy.
- Multistrategic: the system supports the scrapping of different exchanges, and the calculation of possible profits with more strategies.
- SI Good practices: the architecture has been designed carefully, so it makes adding a new exchange/coin/calculation strategy really easy.
- Abstract View: API Rest is available to obtain data, so it makes client integration easier.
- Market research: you can analyze the graphs by supports/resistances auto-generation feature

## Currently supported exchanges
- Binance
- Bitfinex
- Kraken

## Currently supported strategies
- Spatial strategy
- Triangular strategy

## Output example
You can retrive the data at `/values`
```json
{
"basic":{
	"ADA_BTC":{
		"binance-bitfinex":{
			"max_exchange":"bitfinex",
			"max_value":3.946e-5,
			"min_exchange":"binance",
			"min_value":3.945e-5,
			"profit":1.0002534854245881
		},
		"binance-kraken":{
			"max_exchange":"kraken",
			"max_value":3.948e-5,
			"min_exchange":"binance",
			"min_value":3.945e-5,
			"profit":1.0007604562737644
		},
			"bitfinex-kraken":{
			"max_exchange":"kraken",
			"max_value":3.948e-5,
			"min_exchange":"bitfinex",
			"min_value":3.946e-5,
			"profit":1.0005068423720225
		}
	}
}
"triangular":{
	"ADA_BTC":{
		"binance-binance-binance":{
			"btc_usd_exchange":"binance",
			"btc_usd_value":35581.83134952,
			"profit":0.9996322109108438,
			"usd_x_exchange":"binance",
			"usd_x_value":1.40318698,
			"x_btc_exchange":"binance",
			"x_btc_value":3.945e-5
		},
		"binance-binance-bitfinex":{
			"btc_usd_exchange":"binance",
			"btc_usd_value":35581.83134952,
			"profit":0.9993788829303797,
			"usd_x_exchange":"binance",
			"usd_x_value":1.40318698,
			"x_btc_exchange":"bitfinex",
			"x_btc_value":3.946e-5
		"binance-binance-kraken":{
			"btc_usd_exchange":"binance",
			"btc_usd_value":35581.83134952,
			"profit":0.9988726119663824,
			"usd_x_exchange":"binance",
			"usd_x_value":1.40318698,
			"x_btc_exchange":"kraken",
			"x_btc_value":3.948e-5
		}
		...
	}
}
```

Support/Resistance plot:
![Support/Resitance plot](https://imgur.com/xuF3Rgr)

## How to deploy

Windows: you will need to install Erlang/Elixir
```` 
mix deps.get
mix deps.compile
mix compile
web-server\run_production.sh
main-app\run_production.bat
````

Linux:
```` 
sudo apt install elixir
mix deps.get
mix deps.compile
mix compile
web-server\run_production.sh
main-app\run_production.bat
````

Check the config file for proper MySQL fields.

