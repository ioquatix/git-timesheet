# Copyright, 2015, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module Git
	module Timesheet
		class Entry
			def initialize(timestamp, message, repository)
				@timestamp = timestamp
				@message = message
				@repository = repository
			end
			
			attr :timestamp
			attr :message
			attr :repository
			
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
					
					Entry.new(timestamp, message, git_root)
				end
			end
		end
	end
end
