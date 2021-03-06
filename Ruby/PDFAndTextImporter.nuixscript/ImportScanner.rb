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
		@pdf_regex = /([0-9a-f\-]{32,})\.pdf$/i
		@txt_regex = /([0-9a-f\-]{32,})\.txt$/i
	end

	def each_found_file(&block)
		glob_expression = File.join(@directory,"**","*.*")
		puts "Finding files: #{glob_expression}"
		Dir.glob(glob_expression) do |file|
			if file =~ @pdf_regex || file =~ @txt_regex
				# The test above should have stored the group matched in $1
				guid_or_md5 = $1.gsub("-","")
				if guid_or_md5.size == 32
					is_pdf = false
					if file =~ /\.pdf$/i
						is_pdf = true
					end
					
					if (is_pdf && @find_pdf) || (!is_pdf && @find_text)
						found_file = FoundFile.new(guid_or_md5,file,is_pdf)
					end
					
					yield found_file
				end
			end
		end
	end
end