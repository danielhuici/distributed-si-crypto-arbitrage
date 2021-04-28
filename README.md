# Software Infraestructuture for multistrategic arbitrage of Cryptocurrency

An Elixir implementation of a cryptocurrency arbitrage software. It scrappes coin values from several exchanges and calculates the possible profit by using several strategies. 

- Distributed: the implementation is completly modular, so every module of the system can be deployed on different nodes. It's a fault tolerant, master-worker infraestructure which makes the system more reliable and easier to deploy.
- Multistrategic: the system supports the scrapping of different exchanges, and the calculation of possible profits with more strategies.
- SI Good practices: the architecture has been designed carefully, so it makes adding a new exchange/coin/calculation strategy really easy.

## Currently supported exchanges
- Binance
- Bitfinex

## Currently supported strategies
- Triangular strategy

## How to deploy

For now, the deploy only supports Windows. It will support Linux in the future.
Elixir must be installed on your machine.

```` 
web-server\run.bat
main-app\run.bat
````

