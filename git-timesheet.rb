#!/usr/bin/env ruby

# Avoid encoding error in Ruby 1.9 when system locale does not match Git encoding
# Binary encoding should probably work regardless of the underlying locale
Encoding.default_external='binary' if defined?(Encoding)

require 'optparse'
require 'time'

options = {}

OptionParser.new do |opts|
	opts.banner = "Usage: git-timesheet [options]"

	opts.on("-s", "--since [TIME]", "Start date for the report (default is 1 week ago)") do |time|
		options[:since] = time
	end
	
	opts.on("-a", "--author [EMAIL]", "User for the report (default is the author set in git config)") do |author|
		options[:author] = author
	end

	opts.on(nil, '--authors', 'List all available authors') do |authors|
		options[:authors] = authors
	end
end.parse!

options[:root] = ARGV.shift || '.'
options[:since] ||= '1 week ago'

class Entry
	def initialize(timestamp, message)
		@timestamp = timestamp
		@message = message
	end
	
	attr :timestamp
	attr :message
	
	def <=> other
		self.timestamp <=> other.timestamp
	end
	
	def self.load(git_root, since: nil, author: nil)
		log_lines = []
		
		Dir.chdir(git_root) do
			log_lines = `git log --no-merges --simplify-merges --author="#{author.gsub('"','\\"')}" --format="%ad %s <%h>" --date=iso --since="#{since.gsub('"','\\"')}"`.split("\n")
		end
		
		log_lines.collect do |line|
			timestamp = Time.parse line.slice!(0,25)
			message = line
			
			Entry.new(timestamp, message)
		end
	end
end

BLOCK_SLOP_DURATION = 3600 * 4

if options[:authors]
	authors = `git log --no-merges --simplify-merges --format="%an (%ae)" --since="#{options[:since].gsub('"','\\"')}"`.strip.split("\n").uniq
	puts authors.join("\n")
else
	options[:author] ||= `git config --get user.email`.strip
	
	entries = Entry.load(options[:root] || Dir.pwd, since: options[:since], author: options[:author])
	
	if entries.empty?
		puts "No entries..."
		exit(0)
	end
	
	entries.sort!
	
	previous_entry = entries.shift
	blocks = []
	block = [previous_entry]
	
	entries.each do |entry|
		if (entry.timestamp - previous_entry.timestamp) > BLOCK_SLOP_DURATION
			blocks << block
			block = []
		end
		
		block << entry
		
		previous_entry = entry
	end
	
	# Add the last block
	blocks << block
	total_hours = 0
	blocks.each do |block|
		if block != blocks.first
			puts
		end
		
		duration = (block.last.timestamp - block.first.timestamp) / 3600.0
		total_hours += duration
		
		puts "For period #{block.first.timestamp} -> #{block.last.timestamp}: #{duration.round(2)} hours"
		
		block.each do |entry|
			puts "\t#{entry.timestamp}: #{entry.message}"
		end
	end
	
	puts "TOTAL: #{total_hours.round(2)}"
end
