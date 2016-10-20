require 'open-uri'

total_requests = 0
failed_requests = 0
redirected_requests = 0
files_requested = []
files_requested_count = {}
error_log = File.open("errorlog.txt","w+")

puts 'Downloading file...'

##################TEST ON FRESH LINUX VM!!!!!##############################
#ACTUAL
#open('http://s3.amazonaws.com/tcmg412-fall2016/http_access_log') do |file|
#TEST
open('C:\Users\Jordan\Documents\ruby\test_log.txt') do |file|
  puts 'Parsing file...'
  file.each_line do |line|
    if line =~ /^\S+ - - \[([a-zA-Z0-9\/]*)\S* \S* "(\w*) (\S*).*["] ([0-9]*) \S+/
      date = $1
      request = $2
      url = $3
      code = $4
      date_file_name = date << ".txt"

      #Adds to array of files
      files_requested << url

      #Adds to request counter if request header is detected
      if ['GET','POST', 'HEAD'].include?(request)
        total_requests += 1
      end

#WORK IN PROGRESS
#      if File.exist?(date_file_name)
#        File.open(date_file_name, 'w+') { |date_file|
#        date_file.write(line)
#      }
#      else
#        new_date = File.open(date_file_name, 'w+') { |date_file|
#        date_file.puts line
#      }
#      end

      #Adds to appropriate counter if errors are detected
      if code.to_i >= 400 && code.to_i < 500
        failed_requests += 1
      elsif code.to_i >= 300 && code.to_i < 400
        redirected_requests += 1
      end

    else
      #Places unparsed lines in errorlog.txt
      error_log.puts(line)
    end
  end
end

#Creates hash of files requested => #of times
files_requested.each do |item|
  files_requested_count[item] = 0 if files_requested_count[item].nil?
  files_requested_count[item] = files_requested_count[item] + 1
end

#Finds most requested file
most_requested_value = files_requested_count.values.max
most_requested = files_requested_count.select { |k, v| v == most_requested_value}.keys

#Finds least requested file (all of them...)
#WORK IN PROGRESS
least_requested_value = files_requested_count.values.min
least_requested = files_requested_count.select { |k, v| v == least_requested_value }.keys

#Closes error log after iterations are finished
error_log.close

failed_percentage = (failed_requests.to_f / total_requests) * 100
redirected_percentage = (redirected_requests.to_f / total_requests) * 100

#Display
puts "\n#{total_requests} requests have been made."
puts "Requests/day"
puts "#{failed_percentage.round(2)}% of requests were not successful (#{failed_requests} requests)"
puts "#{redirected_percentage.round(2)}% of requests were redirected (#{redirected_requests} requests)"
puts "Most requested file(s): #{most_requested} (requested #{most_requested_value} time(s))"
puts "Least requested file(s): #{least_requested} (requested #{least_requested_value} time(s))"
puts "\nSome lines could not be parsed.  They are located in errorlog.txt"
