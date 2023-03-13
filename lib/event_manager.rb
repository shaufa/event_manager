require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
  phone_number.gsub!(/[^0-9]/, '')
  if phone_number.length == 11 && phone_number[0] == '1' 
    phone_number[1..10]
  elsif phone_number.length == 10
    phone_number
  else
    'Wrong number'
  end
end

def reg_hour(reg_date)
  reg_date = reg_date.gsub!(/[^0-9]/, ' ').split.map(&:to_i)
  Time.new((2000 + reg_date[2]), reg_date[0], reg_date[1], reg_date[3], reg_date[4]).hour
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

def top_hours(hour_list)
  sorted = hour_list.sort_by { |_key, value| value }.to_h
  "Top hours are: #{sorted.keys.last(2).join(' and ')}"
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

total_hours = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  # zipcode = clean_zipcode(row[:zipcode])
  # legislators = legislators_by_zipcode(zipcode)
  # raw_phone = row[:homephone].dup
  phone_number = clean_phone_number(row[:homephone])

  # form_letter = erb_template.result(binding)

  # save_thank_you_letter(id,form_letter)
  hour = reg_hour(row[:regdate])
  total_hours[hour] += 1

  # puts "#{name}: #{phone_number} <-- #{raw_phone}"
end

p top_hours(total_hours)