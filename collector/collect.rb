#!/usr/bin/env ruby

require './src/all'

# Collects blocks/txes/mempool data and stores it locally for analysis

block_index = $db.oldest_block_index
block_index = nil
fetch_chain $slim_db, block_index
