require 'fileutils'
require 'json'
require 'date'

require './src/BTC'
require './src/utils'
require './src/db'
require './src/index'
require './src/mempool'

$db = DB.new
$mempool = Mempool.new
$processed_db = SlimDB.new(nil, 'slim')
$processed_db.set($db, $mempool)
