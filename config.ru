# Start the development server
#   > rake dev:start
# 
# Start the production server
#   > rake live:start

$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))

require 'app/bootstrap'
run Application 
