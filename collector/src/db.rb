require 'zlib'

# Responsbile for storing the blockchain on disk
# Blocks are compressed using zlib and decompressed on the fly
class DB
  attr_accessor :db_path, :data_path, :time_index, :obj_type

  def initialize(db_path = nil, obj_type = 'data')
    @db_path = ENV['DB_PATH'] || data_path || 'db'
    @obj_type = obj_type
    @data_path = File.join(@db_path, @obj_type)
    @time_index = Index.new(@db_path, "#{obj_type}_time".to_sym)

    validate
  end

  def mkdirs
    FileUtils.mkdir_p data_path
  end

  def view_stats
    gzs = Dir["#{data_path}/*.gz"]
    cmd_output = `du -h #{db_path}`
    log "\n#{cmd_output}"
    log " count: #{gzs.size}"
  end

  def validate
    log 'Validating'
    mkdirs
    view_stats
  end

  def all_local_blocks from=nil, to=nil
    result = []
    all_blocks = Dir["#{data_path}/*gz"].collect { |e| e.split('/').last.split('.').first.to_i }.sort
    if from.nil? && to.nil?
      # return raw block indexes from disk
      result = all_blocks
    else
      # using the time index, only return blocks between the two dates
      throw 'from or to date nil' if from.nil? || to.nil?
      from_date = Date.parse(from)
      to_date = Date.parse(to)
      to_return = []
      all_blocks.each do |block_id|
        if Time.at(@time_index.data[block_id.to_s].to_i).to_date.between?(from_date, to_date)
          to_return.push block_id.to_i
        end
      end
      result = to_return.sort
    end
    log "Estimated time to read #{result.size} blocks: #{(result.size * 0.2 / 60).round(0)} minutes"
    result
  end

  def block_path block_index
    File.join(@data_path, "#{block_index}.gz")
  end

  def oldest_block_index
    Dir["#{data_path}/*.gz"].sort.first.split('/').last.split('.').first.to_i
  rescue
    nil
  end

  def read block_index
    time = Time.now
    if _have? block_index
      file_path = block_path(block_index)
      data = _read_gzip(file_path)
    else
      data = read_from_api(block_index)
      _write(block_index, data)
    end
    @time_index.add block_index, data['time']

    log "Reading #{block_index} (#{Time.at(data['time'])}) took #{(Time.now - time).to_f.round(2)} seconds"
    data
  end

  def read_from_api block_index
    block_api block_index
  end

  def find_missing_blocks
    blockz = all_local_blocks
    if blockz.empty?
      log 'You have no blocks'
    else
      missing_blocks = blockz - (blockz.first..blockz.last).to_a
      if missing_blocks.empty?
        log 'No missing blocks'
      else
        log 'Missing blocks:'
        p missing_blocks
      end
    end
  end

  def log s
    puts "#{obj_type}: #{s}"
  end

  private

  def _write block_index, data
    file_path = File.join(data_path, "#{block_index}.gz")
    file_path = block_path(block_index)
    Zlib::GzipWriter.open(file_path) do |gzip|
      gzip << data.to_json
      gzip.close
    end
    log "Wrote block #{block_index} with time #{Time.at(data['time'])}"
  end

  def _read_gzip file_path
    JSON.parse(Zlib::GzipReader.open(file_path) { |gzip| gzip.read })
  end

  def _have? block_index
    file_path = block_path(block_index)
    File.exists?(file_path) && !File.zero?(file_path)
  end
end

class SlimDB < DB
  attr_accessor :db, :mempool

  def set db, mempool
    @db = db
    @mempool = mempool
  end

  def validate
    super

    if ENV['NO_VALIDATION'].nil?
      index_time = Time.now
      log 'Adding missing indexes'
      i = 0
      (all_local_blocks - @time_index.indexed_keys).each do |missing|
        i += 1
        read missing
        if i % 1000 == 0
          @time_index.commit
        end
      end
      @time_index.commit
      log "Done adding missing indexes #{(Time.now - index_time).round(0)} seconds"
    end

    log 'Done validating'
  end

  def read_from_api block_index
    raw_read_with_mempool @db, @mempool, block_index
  end
end
