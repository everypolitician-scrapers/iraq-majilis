#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def gender_from(str)
  return 'male' if str == 'ذكر'
  return 'female' if str == 'أنثى'
  raise "unknown gender: #{str}"
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('table a[href*="Memberships_Details"]').each do |a|
    link = URI.join url, a.attr('href')
    scrape_person(a.text, link)
  end
end

def scrape_person(name, url)
  noko = noko_for(url)

  data = {
    id:     url.to_s[/ID=(\d+)/, 1],
    name:   name.tidy,
    term:   2014,
    source: url.to_s,
  }
  data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?

  map = {
    gender:      'الجنس',
    birth_place: 'المحافظة',
    birth_date:  'تاريخ ومكان الولادة',
    party:       'الكيان',
    faction:     'الائتلاف',
    religion:    'الديانة',
  }
  map.each do |en, ar|
    data[en] = noko.xpath('//td[not(.//td) and .//span[text()="%s"]]/following-sibling::td/span' % ar).text.tidy
  end
  data[:gender] = gender_from(data[:gender])
  ScraperWiki.save_sqlite(%i[id term], data)
end

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
scrape_list('http://www.miqpm.com/new/Memberships_Index.php?ID=12')
