# nnfee

Attempt to estimate bitcoin fees with neural networks

## components

* [api](api/) - web api for predictions
* [collector](collector/) - prepares data for training/testing
* [estimator](estimator/) - trains/tests

## usage

Easiest way to run this is with docker:

```shell
// start collecting blocks

docker-compose up --build


// once you have blocks you can prepare for training
// this will create training/testing files and move them in the
// correct directory

./prepare


// train the NN

./guestimate --train'


// make prediction. the first element in the array is the fee per byte the other
// is the current mempool size

./guestimate --predict '[2.63,9.66]'
```



## thanks

* https://jochen-hoenicke.de/queue/#1,24h
* https://www.smartbit.com.au/
