#!/usr/bin/env ruby

require 'fileutils'
require 'json'

require './src/BTC'
require './src/utils'
require './src/dumb'
require './src/mempool'
dumb_validate

# $btc = BTC.new('http://kek:kek@172.18.0.2:8332/')
# $btc.getmempoolinfo

# block_index = $btc.getblockcount

if ARGV.size != 1
  puts 'Valid commands: fetch, missing, fetch_missing, fetch_mempool, stats'
  exit 1
end

case ARGV[0]
when 'fetch'
  block_index = dumb_oldest_block_index
  dumb_fetch_chain block_index
when 'missing'
  missing_blocks = dumb_blocks - (dumb_blocks.first..dumb_blocks.last).to_a
  if missing_blocks.empty?
    puts 'No missing blocks'
  else
    puts 'Missing blocks:'
    p missing_blocks
  end
when 'stats'
  # do nothing
else
  puts 'Valid commands: fetch, missing, fetch_missing, stats'
end
