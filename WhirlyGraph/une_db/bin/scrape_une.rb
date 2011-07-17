#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize'
require 'pp'

UNE_BASE_URL = "http://geodata.grid.unep.ch/"

def download_results(page)

end


# r = Mechanize.new
# r.get("file:///#{File.join(File.dirname(__FILE__), 'results.html')}") do |page|
#   p page
# end
# return

a = Mechanize.new
a.get(UNE_BASE_URL) do |page|
  puts "requested #{UNE_BASE_URL}"
  
  # national search
  national_search = a.click( page.link_with(:id => /^National$/) )
  
  puts "Loading National search results"
  # submit search form
  search_results = national_search.form_with(:action => 'results.php') do |f|
  end.click_button
  
  # find the form with the most radio buttons
  puts "analyzing results form"
  
  File.open('results.html', 'w') { |f| f.write(search_results.body) }
  
  radio_counts = []
  search_results.forms.each do |form|
    radios = form.radiobuttons
    next unless radios
    
    radio_counts << radios.size
    
    # radio_counts << form
    # radio_counts << form.radiobuttons_with(:name => /selectedID/).size
  end
  
  p radio_counts
  
  results_form = search_results.forms[radio_counts.index(radio_counts.max)]
  
  
  
  #results_form = search_results.forms.max { |form| form.radiobuttons_with(:name => /selectedID/).size }
  
  # results_form = search_results.form_with(:name => /formGeneric/)
  
  # File.open('results_dump.html', 'w') { |f| f.write(results_form.body) }
  
  radio_buttons = results_form.radiobuttons_with(:name => /selectedID/)
  puts "radio button count: #{radio_buttons.size}"
  
  # (0..radio_buttons.size-1).each do |i|
  (0..1).each do |i|
    puts "processing entry #{i}"
    
    radio = radio_buttons[i]
    
    next unless radio
    
    radio.check
    
    # results_form.click_button
    
    download_options = search_results.click(search_results.link_with(:text => /continue/))
    
    csv_link = download_options.link_with(:text => /Comma Separated File/)
    if ( csv_link )
      download_page = csv_link.click
      file_link = download_page.link_with(:text => /File has been prepared/)
      csv_contents = file_link.click
      
      csv_uri = file_link.uri
      csv_filename = File.basename(csv_uri.path)
      
      File.open("../import/une/#{csv_uri}") { |f| f.write(csv_contents.body) }
    end
    
    
  end
  
end