#!/usr/bin/env ruby

require './src/all'

# Collects blocks/txes/mempool data and stores it locally for analysis

# $db = DB.new
# $btc = BTC.new('http://kek:kek@172.18.0.2:8332/')
# $btc.getmempoolinfo

# block_index = $btc.getblockcount

case ARGV[0]
when 'blocks'
  block_index = $db.oldest_block_index
  fetch_chain $db, block_index
when 'missing_blocks'
  $db.find_missing_blocks
else
  puts 'Valid commands: blocks, missing_blocks'
  exit 1 if ARGV.size != 1
end
