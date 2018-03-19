#!/usr/bin/env ruby

require 'fileutils'
require 'json'

require './src/BTC'
require './src/utils'
require './src/dumb'
require './src/mempool'

$dumb_db = DumbDB.new
# $btc = BTC.new('http://kek:kek@172.18.0.2:8332/')
# $btc.getmempoolinfo

# block_index = $btc.getblockcount

if ARGV.size != 1
  puts 'Valid commands: fetch, missing, fetch_missing, stats'
  exit 1
end

case ARGV[0]
when 'fetch'
  block_index = $dumb_db.dumb_oldest_block_index
  $dumb_db.dumb_fetch_chain block_index
when 'missing'
  blockz = $dumb_db.dumb_blocks
  if blockz.empty?
    puts 'You have no blocks'
  else
    missing_blocks = blockz - (blockz.first..blockz.last).to_a
    if missing_blocks.empty?
      puts 'No missing blocks'
    else
      puts 'Missing blocks:'
      p missing_blocks
    end
  end
when 'stats'
  # do nothing
else
  puts 'Valid commands: fetch, missing, stats'
end
