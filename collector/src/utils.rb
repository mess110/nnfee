def block block_index
  block_hash = $btc.getblockhash block_index
  $btc.getblock block_hash
end

# Recursively gathers data about a block from the API
def block_api block_index
  all = []
  next_page = "https://api.smartbit.com.au/v1/blockchain/block/#{block_index}?limit=1000"
  loop do
    break if next_page.nil?
    puts "Req #{next_page}"
    out = `curl -sS '#{next_page}'`
    json = JSON.parse(out.strip)
    next_page = json['block']['transaction_paging']['next_link']
    all.push json
  end

  original = nil
  while !all.empty?
    original = all.pop if original.nil?
    next if all.empty?
    json = all.pop
    original['block']['transactions'].concat(json['block']['transactions'])
  end

  unless original.nil?
    original = original['block']
    original.delete('transaction_paging')
  end

  original
end

def block_stats b
  transaction_keys = %w(txid hash time first_seen double_spend size vsize input_amount_int output_amount_int fee_int coinbase)
  block_keys = %w(height hash size stripped_size time first_seen difficulty input_count output_count input_amount_int output_amount_int fees_int transaction_count transactions)

  b['transactions'] = b['transactions']
    .collect { |tx| tx.delete_if { |k,v| !transaction_keys.include?(k) } }
    .select { |tx| tx['double_spend'] == false && tx['coinbase'] == false }

  b.delete_if { |k,v| !block_keys.include?(k) }
end

# To limit the prediction range, this method normalizes time and groups
# them by their time slice.
#
# For example, if our max time is 1h, with 6 total_time_slices, the output
# would be put in 6 categories: 0m-10m, 10m-20m, etc
def normalize_time_slice! output, total_time_slices
  old_key = 'confirmation_time'
  new_key = 'confirmation_time_scaled'

  max_time = output.collect { |e| e[old_key] }.max

  element_size = max_time / total_time_slices
  output.each do |e|
    aux = 1
    while aux * element_size < e[old_key] do
      aux += 1
    end
    e[new_key] = aux - 1
  end
end

# When gathering data, we might get 50 of a type and only 2 of another type.
# This methods discards elements of a certain type when there are more than
# a certain treshold
def max_number_of_elements_of_type output, total_time_slices, max = 500
  key = 'confirmation_time_scaled'
  new_output = []
  (total_time_slices - 1).downto(0) do |i|
    new_output.concat(output.select { |e| e if e[key] == i }.take(max))
  end
  new_output
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

# Saves the output as a csv file including keys
#
# There is no good reason why this doesn't use the CSV module
def save_output output, path, keys
  symbol_keys = keys.collect { |e| e.to_sym }
  File.open(path, 'w') do |f|
    f.write(keys.join(',') + "\n")
    output.shuffle.each do |e|
      sub_hash = e.select { |k,v| symbol_keys.include?(k.to_sym) }
      f.write(sub_hash.values.join(',') + "\n")
    end
  end
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

    fee_per_byte = tx['fee_int'].to_f / tx['size'].to_f
    mempool_tx_count = closest['count']
    mempool_megabytes = closest['size'].to_f / 1024.to_f / 1024.to_f
    confirmation_time =  (Time.at(block['first_seen']) - Time.at(tx['first_seen']))

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
      'confirmation_time' => confirmation_time
    })
  end
  puts "Flatten #{block_id} took #{(Time.now - flattening).round(2)} seconds"

  {
    'height' => block_id,
    'time' => block['time'],
    'first_seen' => block['first_seen'],
    'transactions' => transactions
  }
end
