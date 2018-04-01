# Responsible for downloading and selecting the closest mempool state at a
# certain given time
class Mempool
  attr_accessor :mempool

  def initialize
    mempool_raw_path = ENV['MEMPOOL_RAW_PATH'] || 'db/mempool.log'
    mempool_json_path = ENV['MEMPOOL_JSON_PATH'] || 'db/mempool.json'

    unless File.exists?(mempool_raw_path)
      log 'Downloading mempool'
      API.save_mempool_to mempool_raw_path
    end

    time = Time.now
    log 'Reading mempool'
    unless File.exists?(mempool_json_path)
      @mempool = {}
      open(mempool_raw_path) do |pool|
        pool.each_line do |line|
          a = eval(line.strip[0...-1])

          processed = process(a)
          if processed[:count] != 0 && processed[:pending_fee] != 0 && processed[:size] != 0
            @mempool[a[0]] = processed
          end
        end
      end

      File.write(mempool_json_path, @mempool.to_json)
    else
      @mempool = JSON.parse(File.read(mempool_json_path))
    end
    log "Done reading mempool #{(Time.now - time).round(2)} seconds"
  end

  # Returns only mempool areas which include the min and max of first seen
  # in block
  def subset_for transactions
    first_seens = transactions.collect { |tx| tx['first_seen'] }
    extra = 60
    min = (first_seens.min || 0) - extra
    max = (first_seens.max || 0) + extra
    $mempool.mempool.select { |k,v| k.to_i.between?(min, max) }
  end

  def oldest_date
    $mempool.mempool.keys.sort.first.to_i
  end

  def newest_date
    $mempool.mempool.keys.sort.last.to_i
  end

  def closest_mempool(subset, needed)
    needed_key = needed.to_i
    key = subset
      .keys
      .sort_by { |date| (date.to_i - needed_key).abs }
      .first
    @mempool[key]
  end

  def log s
    puts "pool: #{s}"
  end

  private

  def process a
    {
      'time' => a[0],
      'count' => a[1].inject(:+),
      'pending_fee' => a[2].inject(:+),
      'size' => a[3].inject(:+),
    }
  end
end
