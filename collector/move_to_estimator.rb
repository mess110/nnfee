#!/usr/bin/env ruby

# Reads an input file and splits it in training/test data for the estimator
# Files are automagically moved to the csv folder of the estimator

require './src/all'

input_path = 'out.csv'
output_training = 'fee_training.csv'
output_test = 'fee_test.csv'
divider = 10 # 1 in 10 will be added to the test data
final_destination = '../estimator/csv/'

unless File.exists? input_path
  puts "File #{input_path} does not exist"
  exit 1
end

first_line = open(input_path).gets

open(input_path) do |csv|
  open(output_training, 'w') do |training|
    training.puts first_line

    open(output_test, 'w') do |test|
      test.puts first_line

      index = 0
      csv.each_line do |line|
        next if line == first_line
        index += 1
        (index % divider == 0 ? test : training).puts line
      end
    end
  end
end

puts 'Training:'
preview_output output_training

puts "\nTest:"
preview_output output_test

FileUtils.move(output_training, final_destination)
FileUtils.move(output_test, final_destination)

puts "\nDone. Files moved to #{final_destination}"
