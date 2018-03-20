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
  transaction_keys = %w(txid hash time first_seen double_spend size vsize input_amount_int output_amount_int fee_int)
  block_keys = %w(height hash size stripped_size time first_seen difficulty input_count output_count input_amount_int output_amount_int fees_int transaction_count transactions)

  b['transactions']
    .collect { |tx| tx.delete_if { |k,v| !transaction_keys.include?(k) } }
    .select { |tx| tx['double_spend'] == false }

  b.delete_if { |k,v| !block_keys.include?(k) }
end

# To limit the prediction range, this method normalizes time and groups
# them by their time slice.
#
# For example, if our max time is 1h, with 6 total_time_slices, the output
# would be put in 6 categories: 0m-10m, 10m-20m, etc
def normalize_time_slice! output, total_time_slices
  old_key = :confirmation_time
  new_key = :confirmation_time_scaled

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
def max_number_of_elements_of_type output, total_time_slices
  key = :confirmation_time_scaled
  new_output = []
  (total_time_slices - 1).downto(0) do |i|
    new_output.concat(output.select { |e| e if e[key] == i }.take(500))
  end
  new_output
end

# To verify data integrity, its a good idea to easily check headers and how
# many unique elements there are on the last column of the CSV
def preview_output path
  puts `head #{path}`

  a = File.read(path).lines.collect { |l| l.split(',').last.strip }.sort
  p Hash[a.group_by {|x| x}.map {|k,v| [k,v.count]}]
end

# Saves the output as a csv file including keys
#
# There is no good reason why this doesn't use the CSV module
def save_output output, path, keys
  File.open(path, 'w') do |f|
    f.write(keys.join(',') + "\n")
    output.shuffle.each do |e|
      f.write(e.select { |k,v| v if keys.include?(k) }.values.join(',') + "\n")
    end
  end
end
