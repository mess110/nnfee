#!/usr/bin/env ruby

# Reads blocks stored locally and creates an output file for trainig

require './src/all'

output_dir = '/data/out'
FileUtils.mkdir_p output_dir

target_month = 6
target_year = 2017

# from = '2018-01-01' # min: 2017-03-01
# to   = '2018-01-31' # max: 2018-03-01
from = Date.civil(target_year, target_month, 1).to_s
to = Date.civil(target_year, target_month, -1).to_s

path_id = from.gsub('-','')[0...6]
time = Time.now
output_path = File.join(output_dir, "#{path_id}.csv")
all_blocks = $slim_db.all_local_blocks(from, to)

keys = %i(fee_per_byte mempool_megabytes mempool_tx_count confirmation_speed)

def write_tx f, tx, keys
  sub_hash = tx.select { |k,v| keys.include?(k.to_sym) }
  line = sub_hash.values.join(',')
  throw 'missing data' if sub_hash.values.size != keys.size
  f.write "#{line}\n"
end

def add_confirmation_speed tx
  if tx['seconds_to_confirm'] <= 60 * 15    # 15 minutes
    amount = 0
  elsif tx['seconds_to_confirm'] <= 60 * 30 # 30 minutes
    amount = 1
  elsif tx['seconds_to_confirm'] <= 60 * 60 * 1  # 1 hour
    amount = 2
  elsif tx['seconds_to_confirm'] <= 60 * 60 * 4  # 4 hours
    amount = 3
  elsif tx['seconds_to_confirm'] <= 60 * 60 * 12 # 12 hours
    amount = 4
  elsif tx['seconds_to_confirm'] <= 60 * 60 * 24 * 1 # 1 day
    amount = 5
  elsif tx['seconds_to_confirm'] <= 60 * 60 * 24 * 3 # 3 days
    amount = 6
  else
    amount = 7
  end
  tx['confirmation_speed'] = amount
end

open(output_path, 'w') do |f|
  f.write "#{keys.join(',')}\n"

  while !all_blocks.empty?
    newest_block_id = all_blocks.pop
    $slim_db.read(newest_block_id)['transactions'].each do |tx|
      add_confirmation_speed(tx)
      write_tx(f, tx, keys)
    end
  end
end

# output_file = ENV['PREPARE_OUTPUT_FILE'] || 'out.csv'

preview_output(output_path)
# prepare_nn_files(output_file)
puts "Total time preparing: #{(Time.now - time).round(2)} seconds"
