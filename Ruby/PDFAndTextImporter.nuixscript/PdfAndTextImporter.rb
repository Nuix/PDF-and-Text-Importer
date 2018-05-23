# Menu Title: PDF and Text Importer
# Needs Case: true
# Needs Selected Items: false

script_directory = File.dirname(__FILE__)
require File.join(script_directory,"Nx.jar")
java_import "com.nuix.nx.NuixConnection"
java_import "com.nuix.nx.LookAndFeelHelper"
java_import "com.nuix.nx.dialogs.ChoiceDialog"
java_import "com.nuix.nx.dialogs.TabbedCustomDialog"
java_import "com.nuix.nx.dialogs.CommonDialogs"
java_import "com.nuix.nx.dialogs.ProgressDialog"
java_import "com.nuix.nx.digest.DigestHelper"

LookAndFeelHelper.setWindowsIfMetal
NuixConnection.setUtilities($utilities)
NuixConnection.setCurrentNuixVersion(NUIX_VERSION)

load File.join(script_directory,"ImportScanner.rb")

require 'thread'

dialog = TabbedCustomDialog.new("PDF and Text Importer")
dialog.setHelpFile(File.join(script_directory,"Readme.html"))
main_tab = dialog.addTab("main_tab","Main")
main_tab.appendDirectoryChooser("source_directory","Source Directory")
main_tab.appendRadioButton("md5_naming","Files have MD5 naming","naming_group",true)
main_tab.appendRadioButton("guid_naming","Files have GUID naming","naming_group",false)
main_tab.appendCheckBox("import_pdfs","Import PDFs",true)
main_tab.appendCheckBox("import_text","Import Text",true)
main_tab.appendComboBox("text_file_encoding","Text File Encoding",["utf-8","utf-16"])
main_tab.appendCheckBox("append_text","Append Imported Text to Existing Text",true)
main_tab.appendTextField("separator","Appended Text Separator","\\n\\n===== Imported Text =====\\n\\n")
main_tab.enabledOnlyWhenChecked("separator","append_text")
main_tab.appendHeader("Note: \\n = newline, \\t == tab")
main_tab.appendCheckableTextField("tag_updated_items",false,"tag_name","ImportedTextOrPDF","Tag Updated Items with")

dialog.validateBeforeClosing do |values|
	if values["source_directory"].empty? || !java.io.File.new(values["source_directory"]).exists
		CommonDialogs.showWarning("Please choose a valid source directory to import from.")
		next false
	end

	if values["import_pdfs"] == false && values["import_text"] == false
		CommonDialogs.showWarning("Please check 'Import PDFs' and/or 'Import Text'.")
		next false
	end

	if values["tag_updated_items"] && values["tag_name"].strip.empty?
		CommonDialogs.showWarning("Please provide a non-empty tag name.")
		next false
	end

	if !CommonDialogs.getConfirmation("The script needs to close all workbench tabs, proceed?")
		next false
	end

	next true
end

dialog.display
if dialog.getDialogResult == true
	$window.closeAllTabs

	values = dialog.toMap
	source_directory = values["source_directory"]
	md5_naming = values["md5_naming"]
	guid_naming = values["guid_naming"]
	import_pdfs = values["import_pdfs"]
	import_text = values["import_text"]
	text_file_encoding = values["text_file_encoding"]
	append_text = values["append_text"]
	separator = values["separator"].gsub("\\n","\n").gsub("\\t","\t")
	tag_updated_items = values["tag_updated_items"]
	tag_name = values["tag_name"]

	found_file_queue = Queue.new
	found_file_count = 0
	found_pdf_count = 0
	found_text_count = 0
	skipped_count = 0
	updated_item_guids = {}

	ProgressDialog.forBlock do |pd|
		pd.setTitle("PDF and Text Importer")

		pd.logMessage("Source Directory: #{source_directory}")
		pd.logMessage("Matching By: #{md5_naming ? "MD5" : "GUID"}")
		pd.logMessage("Import PDFs: #{import_pdfs}")
		pd.logMessage("Import Text: #{import_text}")
		if import_text
			pd.logMessage("\tText File Encoding: #{text_file_encoding}")
			pd.logMessage("\tAppend Text: #{append_text}")
			pd.logMessage("\tSeparator: #{values["separator"]}")
		end
		pd.logMessage("Tag Update Items: #{tag_updated_items}")
		if tag_updated_items
			pd.logMessage("\tTag Name: #{tag_name}")
		end

		find_thread = Thread.new {
			scanner = ImportScanner.new(source_directory,import_pdfs,import_text)
			scanner.each_found_file do |found_file|
				found_file_queue.push(found_file)
				found_file_count += 1
				if found_file.is_pdf?
					found_pdf_count += 1
				else
					found_text_count += 1
				end
			end
			pd.logMessage("No more files in source directory...")
			# Terminator nil
			found_file_queue.push(nil)
		}

		pdf_importer = $utilities.getPdfPrintImporter
		annotater = $utilities.getBulkAnnotater

		$current_case.withWriteAccess do
			while found_file = found_file_queue.pop
				if pd.abortWasRequested
					break
				end

				pd.setMainStatus(
					"PDF Files: #{found_pdf_count}, " +
					"Text Files: #{found_text_count}, " +
					"Queued Files: #{found_file_queue.size}, " +
					"Skipped Files: #{skipped_count}, " + 
					"Items Updated: #{updated_item_guids.size}"
				)

				pd.setMainProgress(updated_item_guids.size,updated_item_guids.size + found_file_queue.size)

				query = nil
				if md5_naming
					query = "md5:\"#{found_file.id}\""
				else
					query = "guid:\"#{found_file.id}\""
				end

				matching_items = $current_case.search(query)

				if matching_items.size < 1
					id_type = md5_naming ? "MD5" : "GUID"
					pd.logMessage("No matching #{id_type} for '#{found_file.id}': #{found_file.file}")
					skipped_count += 1
					next
				end

				if found_file.is_pdf?
					pd.logMessage("Importing PDF to #{matching_items.size} items: #{found_file.file}")
					matching_items.each do |matching_item|
						pdf_importer.importItem(matching_item,found_file.file)
						updated_item_guids[matching_item.getGuid] = true
					end
				else
					pd.logMessage("Importing Text to #{matching_items.size} items: #{found_file.file}")
					file_text = File.read(found_file.file,:encoding=>"bom|#{text_file_encoding}")
					if append_text
						updated_text = []
						updated_text << matching_items.first.getTextObject.toString
						updated_text << separator
						updated_text << file_text
						updated_text = updated_text.join("")
						matching_items.each do |matching_item|
							matching_item.modify do |item_modifier|
								item_modifier.replaceText(updated_text)
								updated_item_guids[matching_item.getGuid] = true
							end
						end
					else
						matching_items.each do |matching_item|
							matching_item.modify do |item_modifier|
								item_modifier.replaceText(file_text)
								updated_item_guids[matching_item.getGuid] = true
							end
						end
					end

					if tag_updated_items
						pd.setSubStatus("Tagging updated items...")
						annotater.addTag(tag_name,matching_items) do |info|
							pd.setSubProgress(matching_items.size,info.getStageCount)
						end
						pd.setSubProgress(0,1)
						pd.setSubStatus("")
					end
				end
			end
		end
		pd.setCompleted
		pd.setMainStatus(
					"PDF Files: #{found_pdf_count}, " +
					"Text Files: #{found_text_count}, " +
					"Skipped Files: #{skipped_count}, " + 
					"Items Updated: #{updated_item_guids.size}")
		#$window.openTab("workbench",{:search=>"guid:(#{updated_item_guids.keys.join(" OR ")})"})
		if tag_updated_items
			$window.openTab("workbench",{:search=>"tag:\"#{tag_name}\""})
		else
			$window.openTab("workbench",{:search=>""})
		end
	end
end