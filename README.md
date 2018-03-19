# nnfee

Attempt to estimate bitcoin fees with neural networks

## components

* [collector](collector/) - prepares data for training/testing
* [estimator](estimator/) - trains/tests

## usage

Easiest way to run this is with docker:

```
docker-compose up --build
./estimate  --predict '[2.63,9.66]'
```

## thanks

* https://jochen-hoenicke.de/queue/#1,24h
* https://www.smartbit.com.au/
