# collector

Gathers and caches the bitcoin blocks on disk.

Requires ruby 2.4.3, no gem dependencies.

## commands

```
./collect.rb blocks
```

Starts gathering blocks and saves them locally.

Once you have enough blocks, run `prepare.rb` to generate the training and
test CSVs.

```
./prepare.rb
```
