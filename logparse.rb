require 'open-uri'

total_requests = 0
failed_requests = 0
redirected_requests = 0
files_requested = []
files_requested_count = {}
requests_per_month = {}

error_log = File.open("errorlog.txt","w+")
Dir.mkdir './month_logs' unless File.exists?("./month_logs")


puts "\nDownloading file..."

#ACTUAL
open('http://s3.amazonaws.com/tcmg412-fall2016/http_access_log') do |file|
#TEST
#open('.\test_log.txt') do |file|
  puts 'Parsing file...'
  file.each_line do |line|
    if line =~ /^\S+ - - \[([a-zA-Z0-9\/]*)\S* \S* "(\w*) (\S*).*["] ([0-9]*) \S+/
      date = $1
      request = $2
      url = $3
      error_code = $4
      month_year = date.gsub(/^[\d][\d]\//, "")
      month_year = month_year.gsub(/[\/]/, "")
#      date_file_name = month_year << ".txt"
      #Adds to array of files
      files_requested << url

      #Adds to request counter if request header is detected
      if ['GET','POST', 'HEAD'].include?(request)
        total_requests += 1
      end

############################TOO SLOW#####################
      #Checks if file exists.  If so appends line to the end.
#      if File.exist?("./month_logs/#{date_file_name}")
#        File.open("./month_logs/#{date_file_name}", 'w+') { |date_file|
#        date_file.puts line
#      }

      #Creates file if it does not exist and writes the line to it
#      else
#        File.open("./month_logs/#{date_file_name}", "w") { |date_file|
#        date_file.puts line
#      }
#      end
########################################################
      
      #Idea from Adam Mikeal
      if requests_per_month.has_key? "#{month_year}"
        requests_per_month[month_year].push(line)
      else
        requests_per_month[month_year] = Array.new
        requests_per_month[month_year].push(line)
      end



      #Adds to appropriate counter if errors are detected
      if error_code.to_i >= 400 && error_code.to_i < 500
        failed_requests += 1
      elsif error_code.to_i >= 300 && error_code.to_i < 400
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

#Finds least requested file
least_requested_value = files_requested_count.values.min
least_requested = files_requested_count.select { |k, v| v == least_requested_value }.keys

#Creates/adds to monthly files
requests_per_month.each do |k, v|
  log_file = k + ".txt"
  File.open("./month_logs/#{log_file}", "w") do |l|
    l.puts(v)
  end
end

#Closes error log after iterations are finished
error_log.close

failed_percentage = (failed_requests.to_f / total_requests) * 100
redirected_percentage = (redirected_requests.to_f / total_requests) * 100

#Display
puts "\n#{total_requests} total requests have been made."
puts "Requests per month:"
requests_per_month.each do |k, v|
  display_date = k.gsub(/(?<=[a-zA-Z])(?=[0-9])/, ' ')
  puts "#{display_date}: #{v.size} requests"
end
puts "\n#{failed_percentage.round(2)}% of requests were not successful (#{failed_requests} requests)"
puts "#{redirected_percentage.round(2)}% of requests were redirected (#{redirected_requests} requests)"
puts "Most requested file(s): #{most_requested.first} (requested #{most_requested_value} time)"
puts "Least requested file(s): #{least_requested.first} and #{least_requested.size} others (requested #{least_requested_value} time(s))"
puts "\nSome lines may have not been parsed.  They are located in errorlog.txt"
