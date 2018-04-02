def block block_index
  block_hash = $btc.getblockhash block_index
  $btc.getblock block_hash
end

def block_stats b
  transaction_keys = %w(txid hash time first_seen double_spend size vsize input_amount_int output_amount_int fee_int coinbase)
  block_keys = %w(height hash size stripped_size time first_seen difficulty input_count output_count input_amount_int output_amount_int fees_int transaction_count transactions)

  b['transactions'] = b['transactions']
    .collect { |tx| tx.delete_if { |k,v| !transaction_keys.include?(k) } }
    .select { |tx| tx['double_spend'] == false && tx['coinbase'] == false }

  b.delete_if { |k,v| !block_keys.include?(k) }
end

# To verify data integrity, its a good idea to easily check headers and how
# many unique elements there are on the last column of the CSV
def preview_output path
  puts `head #{path}`

  last_columns = []
  open(path) do |csv|
    csv.each_line do |line|
      last_columns.push(line.split(',').last.strip)
    end
  end
  p Hash[last_columns.sort.group_by {|x| x}.map {|k,v| [k,v.count]}]
end

def prepare_nn_files(input_path)
  output_training = 'fee_training.csv'
  output_test = 'fee_test.csv'
  divider = 10 # 1 in 10 will be added to the test data

  unless File.exists? input_path
    puts "File #{input_path} does not exist"
    exit 1
  end

  first_line = open(input_path).gets

  open(input_path) do |csv|
    open(output_training, 'w') do |training|
      training.puts first_line

      open(output_test, 'w') do |test|
        test.puts first_line

        index = 0
        csv.each_line do |line|
          next if line == first_line
          index += 1
          (index % divider == 0 ? test : training).puts line
        end
      end
    end
  end

  puts "\n#{output_training}"
  preview_output output_training

  puts "\n#{output_test}"
  preview_output output_test
end

def raw_read_with_mempool db, mempool, block_id
  flattening = Time.now
  full_block = db.read block_id
  block = block_stats full_block

  subset = mempool.subset_for block['transactions']

  transactions = []
  block['transactions'].each do |tx|
    closest = mempool.closest_mempool(subset, tx['first_seen'])

    if closest.nil?
      puts "Could not find mempool for #{tx['first_seen']} (#{tx['txid']})"
      next
    end

    fee_per_byte = tx['fee_int'].to_f / tx['size'].to_f
    mempool_tx_count = closest['count']
    mempool_megabytes = closest['size'].to_f / 1024.to_f / 1024.to_f
    seconds_to_confirm = (Time.at(block['first_seen']) - Time.at(tx['first_seen'])).to_i

    transactions.push({
      'txid' => tx['txid'],
      'size' => tx['size'],
      'vsize' => tx['vsize'],
      'fee' => tx['fee_int'],
      'first_seen' => tx['first_seen'],
      'time' => tx['time'],

      'fee_per_byte' => fee_per_byte.to_f.round(2),
      'mempool_megabytes' => mempool_megabytes.to_f.round(8),
      'mempool_tx_count' => mempool_tx_count,
      'seconds_to_confirm' => seconds_to_confirm
    })
  end
  db.log "Flatten #{block_id} took #{(Time.now - flattening).round(2)} seconds"

  {
    'height' => block_id,
    'time' => block['time'],
    'first_seen' => block['first_seen'],
    'transactions' => transactions
  }
end

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
