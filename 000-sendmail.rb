#!/usr/bin/ruby

## SEND EMAIL VIA GMAIL

require 'net/smtp'

## SET UP CONNECTION PARAMS

domain = "gmail.com"
username = "testmailniall@gmail.com"
pass = "foobarbaz"


## CREATE MESSAGE
from = "testmailniall@gmail.com"
to = "niall1402@gmail.com"
message = <<END_OF_MESSAGE
From: #{from} 
To: #{to}
Subject: #{ARGV[0]}

#{ARGV[1]} 

END_OF_MESSAGE

## SEND MESSAGE
smtp = Net::SMTP.new('smtp.gmail.com', 587 )
smtp.enable_starttls
smtp.start(domain, username, pass, :login) do |smtp|
        smtp.send_message message, from, to

end