require 'zlib'

# Responsbile for storing the blockchain on disk
# Blocks are compressed using zlib and decompressed on the fly
class DB
  attr_accessor :db_path, :data_path

  def initialize(db_path = 'db')
    @db_path = ENV['DATA_PATH'] || db_path
    @data_path = File.join(@db_path, 'data')
    validate
  end

  def validate
    FileUtils.mkdir_p data_path

    gzs = Dir["#{data_path}/*.gz"]
    puts `du -h #{db_path}`
    puts "#{gzs.size} blocks"
    # gzs.each do |s|
    # end
  end

  def all_local_blocks
    Dir["#{data_path}/*gz"].collect { |e| e.split('/').last.split('.').first.to_i }.sort
  end

  def fetch_chain block_index
    block_index = 514132 if block_index.nil?
    while block_index > 1
      block_index -= 1
      puts "Reading #{block_index}"
      data = read(block_index)
      puts "Block time: #{data['time']} - #{Time.at(data['time'])}"
    end
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
      data = block_api(block_index)
      _write(block_index, data)
    end
    puts "Reading #{block_index} took #{(Time.now - time).to_f.round(2)} seconds"
    data
  end

  private

  def _write block_index, data
    file_path = File.join(data_path, "#{block_index}.gz")
    file_path = block_path(block_index)
    Zlib::GzipWriter.open(file_path) do |gzip|
      gzip << data.to_json
      gzip.close
    end
    puts "Wrote block #{block_index} with time #{Time.at(data['time'])}"
  end

  def _read_gzip file_path
    JSON.parse(Zlib::GzipReader.open(file_path) { |gzip| gzip.read })
  end

  def _have? block_index
    file_path = block_path(block_index)
    File.exists?(file_path) && !File.zero?(file_path)
  end
end
