#!/usr/bin/env ruby

require './src/all'

$dumb_db = DumbDB.new
# $btc = BTC.new('http://kek:kek@172.18.0.2:8332/')
# $btc.getmempoolinfo

# block_index = $btc.getblockcount

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
else
  puts 'Valid commands: blocks, mempool, missing_blocks'
  exit 1 if ARGV.size != 1
end
