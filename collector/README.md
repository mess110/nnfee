# collector

Gathers and caches the bitcoin blocks on disk.

Requires ruby 2.4.3, no gem dependencies.

## commands

```
./collect.rb fetch
```

Starts gathering blocks and saves them in the disk 'db'.

Once you have enough blocks, run `analyze.rb` to generate `out.csv`:

```
./analyze.rb
```

Once you have the `out.csv` file, split it in training/test data and use it
in the [estimator](/estimator/).
