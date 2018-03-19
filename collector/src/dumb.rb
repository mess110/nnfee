require 'zlib'

class DumbDB
  attr_accessor :dumb_path, :dumb_data_path, :dumb_index_path

  def initialize
    @dumb_path = 'dumb_db2'
    @dumb_data_path = File.join(@dumb_path, 'data')
    @dumb_index_path = File.join(@dumb_path, 'index')
    dumb_validate
  end

  def dumb_validate
    FileUtils.mkdir_p dumb_data_path
    FileUtils.mkdir_p dumb_index_path

    gzs = Dir["#{dumb_data_path}/*.gz"]
    puts `du -h #{dumb_path}`
    puts "#{gzs.size} blocks"
    # gzs.each do |s|
    # end
  end

  def dumb_blocks
    Dir["#{dumb_data_path}/*gz"].collect { |e| e.split('/').last.split('.').first.to_i }.sort
  end

  def dumb_fetch_chain block_index
    block_index = 514132 if block_index.nil?
    while block_index > 1
      block_index -= 1
      puts "Reading #{block_index}"
      data = dumb_read(block_index)
      puts "Block time: #{data['time']} - #{Time.at(data['time'])}"
    end
  end

  def dumb_block_path block_index
    File.join(@dumb_data_path, "#{block_index}.gz")
  end

  def dumb_oldest_block_index
    Dir["#{dumb_data_path}/*.gz"].sort.first.split('/').last.split('.').first.to_i
  rescue
    nil
  end

  def dumb_read block_index
    time = Time.now
    if _dumb_have? block_index
      file_path = dumb_block_path(block_index)
      data = _read_gzip(file_path)
    else
      data = block_api(block_index)
      _dumb_write(block_index, data)
    end
    puts "Reading #{block_index} took #{(Time.now - time).to_f.round(2)} seconds"
    data
  end

  private

  def _dumb_write block_index, data
    file_path = File.join(dumb_data_path, "#{block_index}.gz")
    file_path = dumb_block_path(block_index)
    Zlib::GzipWriter.open(file_path) do |gzip|
      gzip << data.to_json
      gzip.close
    end
    puts "Wrote block #{block_index} with time #{Time.at(data['time'])}"
  end

  def _read_gzip file_path
    JSON.parse(Zlib::GzipReader.open(file_path) { |gzip| gzip.read })
  end

  def _dumb_have? block_index
    file_path = dumb_block_path(block_index)
    File.exists?(file_path) && !File.zero?(file_path)
  end
end
