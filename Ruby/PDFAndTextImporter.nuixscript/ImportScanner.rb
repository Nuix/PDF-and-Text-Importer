class FoundFile
	attr_accessor :id
	attr_accessor :file

	def initialize(id,file,is_pdf)
		@id = id
		@file = file
		@is_pdf = is_pdf
	end

	def is_pdf?
		return @is_pdf == true
	end

	def is_text?
		return !is_pdf?
	end
end

class ImportScanner
	def initialize(directory,find_pdf,find_text)
		@directory = directory
		@find_pdf = find_pdf
		@find_text = find_text
	end

	def each_found_file(&block)
		glob_expression = File.join(@directory,"**","*.*")
		puts "Finding files: #{glob_expression}"
		Dir.glob(glob_expression) do |file|
			if file =~ /([0-9a-f\-]{32,})\.pdf$/i || file =~ /([0-9a-f\-]{32,}).txt$/i
				# The test above should have stored the group matched in $1
				guid_or_md5 = $1.gsub("-","")
				if guid_or_md5.size == 32
					is_pdf = false
					if file =~ /\.pdf$/i
						is_pdf = true
					end
					found_file = FoundFile.new(guid_or_md5,file,is_pdf)
					yield found_file
				end
			end
		end
	end
end