#!/usr/bin/env ruby

require 'fileutils'
require 'json'

require './src/BTC'
require './src/utils'
require './src/dumb_db'
require './src/mempool'

$dumb_db = DumbDB.new
$mempool = Mempool.new

output = []

all_blocks = $dumb_db.dumb_blocks.reverse.take(5)

puts "Analyzing #{all_blocks.size} blocks."

while !all_blocks.empty?
  newest_block_id = all_blocks.pop
  puts newest_block_id
  block = block_stats $dumb_db.dumb_read newest_block_id

  # flatten the data
  block['transactions'].each do |e|
    closest = $mempool.closest_mempool(e['first_seen'])

    fee_per_byte = e['fee_int'].to_f / e['size'].to_f
    tx_size = e['size']
    mempool_size = $mempool.mempool[closest][:count]
    mempool_bytes = $mempool.mempool[closest][:size].to_f / 1024.to_f / 1024.to_f
    confirmation_time =  (Time.at(block['first_seen']) - Time.at(e['first_seen']))

    output.push({
      fee_per_byte: fee_per_byte.to_f.round(2),
      tx_size: tx_size.to_f.round(1),
      mempool_size: mempool_size,
      mempool_bytes: mempool_bytes.to_f.round(8),
      confirmation_time: confirmation_time
    })
  end
end

output.shuffle!

# get maximum confirmation_time
max_time = 0.0
output.each do |e|
  if e[:confirmation_time] > max_time
    max_time = e[:confirmation_time]
  end
end

output.each do |e|
  conf = e[:confirmation_time]
  if conf > max_time / 3 * 2
    e[:confirmation_time] = 2
  elsif conf > max_time / 3
    e[:confirmation_time] = 1
  else
    e[:confirmation_time] = 0
  end
end

new_output = []
new_output.concat(output.select { |e| e if e[:confirmation_time] == 0 }.take(1000))
new_output.concat(output.select { |e| e if e[:confirmation_time] == 1 }.take(1000))
new_output.concat(output.select { |e| e if e[:confirmation_time] == 2 }.take(1000))

output = new_output

output_file = 'out.csv'
# keys = %i(fee_per_byte tx_size mempool_size mempool_bytes confirmation_time)
keys = %i(fee_per_byte mempool_bytes confirmation_time)

File.open(output_file, 'w') do |f|
  f.write(keys.join(',') + "\n")
  output.shuffle.each do |e|
    f.write(e.select { |k,v| v if keys.include?(k) }.values.join(',') + "\n")
  end
end

puts `head #{output_file}`
