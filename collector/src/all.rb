require 'date'
require 'fileutils'
require 'json'
require 'net/http'

require './src/modules/missing_blocks'
require './src/modules/validation'
require './src/modules/navigation'

require './src/BTC'
require './src/utils'
require './src/db'
require './src/index'
require './src/mempool'

puts 'Staring collector'

def debugger_help
  puts "\n" * 2

  puts <<-EOS
  Welcome to the collector debugger.

  $db, $mempool, $slim_db

  EOS
end

$db = DB.new
$mempool = Mempool.new
$slim_db = SlimDB.new(nil, 'slim')
$slim_db.set($db, $mempool)
