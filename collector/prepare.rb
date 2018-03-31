#!/usr/bin/env ruby

# Reads blocks stored locally and creates an output file for trainig

require './src/all'

from = '2018-02-01' # min: 2017-03-01
to   = '2018-02-28' # max: 2018-03-01

time = Time.now

all_blocks = $slim_db.all_local_blocks(from, to)

output = []
while !all_blocks.empty?
  newest_block_id = all_blocks.pop
  puts '-' * 80
  ze_block = $slim_db.read newest_block_id
  output.concat(ze_block['transactions'])
end
output.shuffle!
if output.empty?
  puts 'No transactions'
  exit 1
end

total_time_slices = 10

normalize_time_slice!(output, total_time_slices)

# output = max_number_of_elements_of_type(output, total_time_slices, 1000)

output_file = ENV['PREPARE_OUTPUT_FILE'] || 'out.csv'
keys = %i(fee_per_byte mempool_megabytes mempool_tx_count time_slice)

save_output(output, output_file, keys)
preview_output(output_file)
prepare_nn_files(output_file)
puts "Total time preparing: #{(Time.now - time).round(2)} seconds"
