require 'atk_toolbox'
require 'nokogiri'
require 'open-uri'

def get_text(url)
    text_nodes = Nokogiri::HTML.parse(`curl -fsSL '#{url}'`).xpath('//text()').map(&:text)
    # remove javascript/html junk
    good_nodes = []
    for each in text_nodes
        if not( (each =~ /\<\w.+\>/) || (each =~ /\bfunction\b|\.createElement|async|catch\(e\)|";|\{[\s\S]*\}/))
            good_nodes << each
        end
    end
    # remove whitespace
    good_nodes = good_nodes.compact.map{|each| each.gsub!(/[\n\r\s]+/, " ")}.compact.select{|each| each.strip.size > 2}.map(&:strip)
    # get wordlist
    words = good_nodes.join(" ")
    words.gsub!(/[^\w ]/, "")
    words = words.split(/\s+/).select{|each| not(each =~ /\d+/)}.map(&:downcase).uniq
    return words
end


sites = [
    'http://www.ethosgroup.com',
    'https://www.pingidentity.com/en.html',
    'https://careers.publicissapient.com/',
    'http://careerfair.sec.tamu.edu/students/companies#!&detail_company_id=311',
]
stop_words = ['the', 'at', 'there', 'some', 'my','of', 'be', 'use', 'her', 'than','and', 'this', 'an', 'would', 'first','a', 'have', 'each', 'make', 'water','to', 'from', 'which', 'like', 'been','in', 'or', 'she', 'him', 'call','is', 'one', 'do', 'into', 'who','you', 'had', 'how', 'time', 'oil','that', 'by', 'their', 'has', 'its','it', 'word', 'if', 'look', 'now','he', 'but', 'will', 'two', 'find','was', 'not', 'up', 'more', 'long','for', 'what', 'other', 'write', 'down','on', 'all', 'about', 'go', 'day','are', 'were', 'out', 'see', 'did','as', 'we', 'many', 'number', 'get','with', 'when', 'then', 'no', 'come','his', 'your', 'them', 'way', 'made','they', 'can', 'these', 'could', 'may','I', 'said', 'so', 'people', 'part',]
filename = "bs_words.json"
all_words = JSON.load(FS.read(filename) || "{}")
all_words['words'] ||= {}
for each_site in sites
    words = get_text(each_site)
    all_words['sites'] ||= []
    if not all_words['sites'].include?(each_site)
        all_words['sites'].push(each_site)
        for each in words
            # init to 0
            all_words['words'][each] ||= 0
            # increment
            all_words['words'][each] += 1
        end
    end
end
all_words['words'] = all_words['words'].delete_if {|k,v| stop_words.include?(k) }
all_words['words'] = Hash[ all_words['words'].sort_by {|k, v| -v} ]

FS.write(all_words.to_json, to: filename)

