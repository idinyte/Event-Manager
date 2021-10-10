require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(number)
 number = number.scan(/[0-9]+/).join('')
 number = number[1..11] if number.length == 11 && number[0] == '1'
 return number if number.length == 10
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

reg_hours = []
reg_w_days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone = clean_phone_numbers(row[:homephone])
  reg_date = DateTime.strptime(row[:regdate], '%m/%d/%y %k:%M')
  reg_hours.push(reg_date.strftime('%k').to_i)
  reg_w_days.push(reg_date.strftime('%A'))
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
end

most_frequent_hour = reg_hours.max_by { |i| reg_hours.count(i)}
puts "Most frequent registration hour: #{most_frequent_hour}"
most_frequent_w_day = reg_w_days.max_by { |i| reg_w_days.count(i)}
puts "Most frequent registration week day: #{most_frequent_w_day}"