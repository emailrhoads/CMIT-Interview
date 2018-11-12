#!/usr/bin/env ruby

def create_template(filename)
  all_lines = File.readlines(filename)
  line_lenghts = all_lines.map{ |line| line.length }
  mode_line_len = get_mode(line_lenghts)

  long_enough_lines = all_lines.select { |line| line.length >= mode_line_len}
  all_lines_parsed = long_enough_lines.map { |line| line.split() }
  header_parsed = all_lines_parsed[0]
  header_index = all_lines_parsed.find_index(header_parsed)
  header_line = long_enough_lines[header_index]

  #need a space in front of the indexed value to ensure 
  # it is a delimiter (not subset of other field)
  starting_positions = header_parsed.map { |column| 
  	header_line.index(" "+column) } 
  ending_positions = starting_positions.drop(1).concat [header_line.length]
  slices = (0..header_parsed.length-1).map { |i| 
  	starting_positions[i]..ending_positions[i]-1 } 
  layout = (0..header_parsed.length-1).map { |i| 
  	[header_parsed[i], slices[i]] }.to_h
  layout
end

def get_mode(arr)
  freq = arr.each_with_object(Hash.new(0)) { |v, h| h[v] += 1 } 
  arr.max_by { |v| freq[v] }
end

def convert_delimited_file_to_array(filename, template)
  all_delimited_by_template = File.open(filename,'r').map { |line|
  	parse_elements(line, template) }
end 

def parse_elements(line, template)
  template.map { |k, v | e = line.slice(v); e && e.strip }
end

def get_hash_index(hash, key)
  hash.find_index { |k, _| k==key }
end

def get_delta(row, i1, i2, regex: /\d+/)
  v1, v2 = row[i1][regex], row[i2][regex]
  v1 && v2 ? (v1.to_i - v2.to_i).abs : "n/a"
end

def add_deltas(arr, index1, index2, regex: /\d+/)
  relevant_rows = arr.select { |row| row[index1] != nil && row[index2] != nil }
  with_deltas = relevant_rows.map { |row| 
  	row.concat [get_delta(row, index1, index2, regex: regex)] }
end

def sort_on_delta(array, sort_column: -1)
  array.sort_by { |row| row[sort_column] } 
end

def process_file(filename, col1, col2, regex)
  layout = create_template(filename)
  data_array = convert_delimited_file_to_array(filename, layout)
  #p data_array
  scrubbed_array = data_array.select{ |row| row[0] && row[0][regex] }

  col1_index = get_hash_index(layout, col1)
  col2_index = get_hash_index(layout, col2)
  data_with_deltas = add_deltas(scrubbed_array, col1_index, col2_index)
  remove_na = data_with_deltas.select { |row| row[-1] != "n/a" }
  sorted_array = sort_on_delta(remove_na, sort_column: -1)
  sorted_array[0][0]
end

#If this is what you meant by avoid hardcoding...
#file_to_process = ARGV[0]
#column1_name = ARGV[1]
#column2_name = ARGV[2]
#columns_for_good_row = ARGV[3]

file_to_process = "w_data.dat"
col1 = "MxT"
col2 = "MnT"
first_column_data_quality_regex = /\d+/
p process_file(file_to_process, col1, col2, first_column_data_quality_regex)

file_to_process = "soccer.dat"
col1 = "F"
col2 = "A"
first_column_data_quality_regex = /[A-z]{5}+/
p process_file(file_to_process, col1, col2, first_column_data_quality_regex)
