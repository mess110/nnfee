#!/usr/bin/env ruby

# Collects blocks/txes/mempool data and stores it locally for analysis

require './src/all'

loop do
  json = json_get('http://nnfee_harmony_1:5678/')
  puts json
  $slim_db.read json['last_block_index']
  if json['last_block_index'] <= 2
    puts 'all blocks downloaded'
    break
  end
end
