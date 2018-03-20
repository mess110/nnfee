#!/usr/bin/env ruby

require 'fileutils'
require 'json'

require './src/BTC'
require './src/utils'
require './src/dumb_db'
require './src/mempool'

$dumb_db = DumbDB.new
# $btc = BTC.new('http://kek:kek@172.18.0.2:8332/')
# $btc.getmempoolinfo

# block_index = $btc.getblockcount

help = 'Valid commands: blocks, mempool, missing_blocks, stats'

if ARGV.size != 1
  puts help
  exit 1
end

case ARGV[0]
when 'blocks'
  block_index = $dumb_db.dumb_oldest_block_index
  $dumb_db.dumb_fetch_chain block_index
when 'mempool'
  $mempool = Mempool.new
  puts 'Done'
when 'missing_blocks'
  blockz = $dumb_db.all_local_blocks
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
  puts 'Done'
else
  puts help
end
