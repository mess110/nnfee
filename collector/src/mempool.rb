# Responsible for downloading and selecting the closest mempool state at a
# certain given time
class Mempool
  attr_accessor :mempool

  def initialize
    mempool_3m_js = 'dumb_db/3m.js'
    mempool_3m = 'dumb_db/3m.json'

    unless File.exists?(mempool_3m_js)
      puts 'Downloading mempool'
      `curl https://dedi.jochen-hoenicke.de/queue/3m.js > #{mempool_3m_js}`
    end

    unless File.exists?(mempool_3m)
      puts 'Saving mempool'
      lines = File.read(mempool_3m_js).split("\n")
      lines.pop
      lines.reverse!
      lines.pop
      lines.reverse!
      json = JSON.parse("[#{lines.join('')[0...-1]}]")
      File.write(mempool_3m, json.to_json)
    end

    json = _read_mempool(mempool_3m)
    @mempool = json
  end

  # Example usage:
  #
  # closest_mempool(1521207597)
  def closest_mempool(needed)
    @mempool
      .keys
      .sort_by { |date| (Time.at(date).to_i - Time.at(needed).to_i).abs }
      .first
  end

  private

  def _read_mempool path
    JSON.parse(File.read(path))
      .collect { |e| { e[0] => { time: e[0], count: e[1].inject(:+), pending_fee: e[2].inject(:+), size: e[3].inject(:+) } } }
      .reduce Hash.new, :merge
  end
end
