#!/usr/bin/env ruby

require 'curb'
require 'nokogiri'
require 'csv'


# parses product at url and writes to opened(!) csv file
def parse_prod url, csv
  prod_page = Curl.get(url)
  html = Nokogiri::HTML(prod_page.body_str)

  name = html.at("//h1[@itemprop='name']").to_s.split(/<\/.*>/)[2].strip
  info_node = html.css(".attribute_labels_lists li")

  info_node.each do |li|  
    csv << [ name+"-"+li.css(".attribute_name").text.strip,
             li.css(".attribute_price").text.strip,
             html.at("//span[@id='view_full_size']/img[@id='bigpic']/@src") ]
  end
end

if __FILE__ == $0

  argv = ARGF.argv
  if not argv.size == 2
    puts "Wrong format! USAGE: script.rb url-to-parse path/to/file"
  end

  csv = CSV.open(argv[1], "w")
  
  begin
    origin_url = argv[0]
    cat_page = Curl.get(origin_url)
       
    cat_html = Nokogiri::HTML(cat_page.body_str)
    page_count = cat_html.at("//*[@id='pagination_bottom']/ul/li[6]/a/span").text.to_i
    
    for i in 2..(page_count + 1)
      
      cat_html.css(".product_img_link").each do |prod|
        url = prod.at("@href").text
        parse_prod url, csv
      end

      puts "#{'%.2f' % ((i - 1)/page_count.to_f * 100)}%"

      if i <= page_count
        next_page_url = origin_url + "?p=" + i.to_s

        cat_page = Curl.get(next_page_url)
        cat_html = Nokogiri::HTML(cat_page.body_str)
      end
    end
    
  ensure
    csv.close
  end
end
