require 'net/https'
require 'rexml/document'


begin
  f = File.new("data.txt", "r") 
rescue Errno::ENOENT
  #File doesn't exists, fill it with sample data
  f = File.new("data.txt", "w")
  info = {
    "so" => "",
    "eo" => "",
    "aced" => "",
    "po" => "",
    "ges" => "",
    "ppi" => ""
  }
  Marshal.dump(info,f)
  f.close
  f = File.new("data.txt", "r")
end

info = Marshal.load(f)
f.close

urls = {
  "po" => "/external/announcementsRSS.do?announcementBoardId=243496",
  "so" => "/external/announcementsRSS.do?announcementBoardId=243523",
  "aced" => "/external/announcementsRSS.do?announcementBoardId=244762", 
  "ges" => "/external/announcementsRSS.do?announcementBoardId=243508",
  "ppi" => "/external/announcementsRSS.do?announcementBoardId=243511",
  "eo" => "/external/announcementsRSS.do?announcementBoardId=243514"
}


actual_info = ""
urls.each { |id,url|
  begin
    http = Net::HTTP.new('fenix.ist.utl.pt', '443') 
    http.use_ssl = true
    http.start do |http|
      request = Net::HTTP::Get.new(url)
      response = http.request(request)
      response.value
      actual_info = response.body
    end

  rescue Net::HTTPExceptions
    next #do nothing if couldn't get feed, it'll in the near future
  end

  if info[id] != actual_info   
    info[id] = actual_info

    doc = REXML::Document.new(info[id])
    root = doc.root
    title = String.new(doc.elements["*/channel/item/title"].text)
    desc = String.new(doc.elements["*/channel/item/description"].text)
    desc = desc.gsub(/<[^>]*>/,'')

    begin
      http = Net::HTTP.new('twitter.com', '443')
      http.use_ssl = true
      http.start do |http|
        limit = 140 - (2 + 2 + 2 + title.length)
        request = Net::HTTP::Post.new('/statuses/update.xml')
        request.basic_auth '<username>', '<password>'
        request.set_form_data({"status"=>id.upcase+"::"+title+"::"+desc.slice(0,limit)})
        response = http.request(request)
        response.value
      end
    rescue Net::HTTPExceptions
      #The submission to twitter failed, forget it! (critical)
    end
  end
}

f = File.new("data.txt", "w")
Marshal.dump(info,f)
f.close
