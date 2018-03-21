#!/usr/bin/env ruby

# Reads blocks stored locally and creates an output file for trainig

require './src/all'

time = Time.now
$dumb_db = DumbDB.new
$mempool = Mempool.new

# all_blocks = $dumb_db.all_local_blocks
all_blocks = $dumb_db.all_local_blocks.reverse.take(5)
# all_blocks = $dumb_db.all_local_blocks.each_slice(5).map(&:last)

puts "Preparing from #{all_blocks.size} blocks."

output = []
while !all_blocks.empty?
  newest_block_id = all_blocks.pop
  block = block_stats $dumb_db.read newest_block_id

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

total_time_slices = 8

normalize_time_slice!(output, total_time_slices)

output = max_number_of_elements_of_type(output, total_time_slices, 1000)

output_file = ENV['PREPARE_OUTPUT_FILE'] || 'out.csv'
keys = %i(fee_per_byte mempool_bytes confirmation_time_scaled)

save_output(output, output_file, keys)
preview_output(output_file)
prepare_nn_files(output_file)
puts "Total time preparing: #{(Time.now - time).round(2)} seconds"
