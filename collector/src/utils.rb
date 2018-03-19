def block block_index
  block_hash = $btc.getblockhash block_index
  $btc.getblock block_hash
end

def block_api block_index
  all = []
  next_page = "https://api.smartbit.com.au/v1/blockchain/block/#{block_index}?limit=100"
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
