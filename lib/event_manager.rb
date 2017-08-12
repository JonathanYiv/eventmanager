require "csv"
require 'sunlight/congress'
require 'erb'
require 'date'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

puts "EventManager initialized!"

def clean_zipcode(zipcode)
	zipcode.to_s.rjust(5, "0")[0..4]
end

def legislators_by_zipcode(zipcode)
	Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, form_letter)
	Dir.mkdir("output") unless Dir.exists? "output"

	filename = "output/thanks_#{id}.html"

	File.open(filename, 'w') do |file|
		file.puts form_letter
	end
end

def clean_phone_number(phone_number)
	phone_number.delete!('-(). ')
	phone_number[0] = '' if phone_number[0] == "1" && phone_number.length == 11

	if phone_number.length != 10
		phone_number = "(000) 000-0000"
	end
	phone_number
end

def clean_time(time)
	format = "%m/%d/%y %H:%M"
	DateTime.strptime(time, format)
end

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

hours = []
days = []

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol
contents.each do |row|
	id = row[0]
	name = row[:first_name]
	phone_number = clean_phone_number(row[:homephone])
	hour = clean_time(row[:regdate]).hour
	hours.push(hour)
	day = clean_time(row[:regdate]).wday
	days.push(day)

	zipcode = clean_zipcode(row[:zipcode])

	legislators = legislators_by_zipcode(zipcode)

	form_letter = erb_template.result(binding) # the result and binding parts are still a bit ambiguous to me

	save_thank_you_letters(id, form_letter)

	puts "#{name} #{phone_number} #{hour}"
end

frequency = hours.inject(Hash.new(0)) { |freq, hour| freq[hour] += 1; freq }
puts frequency

frequency_of_days = days.inject(Hash.new(0)) { |freq, day| freq[day] += 1; freq }
puts frequency_of_days