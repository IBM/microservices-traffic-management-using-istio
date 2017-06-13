#!/usr/bin/ruby
#
# Copyright 2017 Istio Authors
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

require 'webrick'
require 'mysql'

if ARGV.length < 1 then
    puts "usage: #{$PROGRAM_NAME} port"
    exit(-1)
end

port = Integer(ARGV[0])

server = WEBrick::HTTPServer.new :BindAddress => '0.0.0.0', :Port => port

trap 'INT' do server.shutdown end

  paperback = "default"
  publisher = "default"
  language = "default"
  isbnA = "default"
  isbnB = "default"
  details_resp = '
  <h4 class="text-center text-primary">Book Details</h4>
  <dl>
  <dt>Paperback:</dt>' + paperback + '
  <dt>Publisher:</dt>' + publisher + '
  <dt>Language:</dt>' + language + '
  <dt>ISBN-10:</dt>' + isbnA + '
  <dt>ISBN-13:</dt>' + isbnB + '
  </dl>
  '
dbHost = ENV['MYSQL_DB_HOST']
dbPort = Integer(ENV['MYSQL_DB_PORT'])
dbUser = ENV['MYSQL_DB_USER']
dbPass = ENV['MYSQL_DB_PASSWORD']



server.mount_proc '/health' do |req, res|
    res.status = 200
    res.body = 'Details is healthy'
    res['Content-Type'] = 'text/html'
end

server.mount_proc '/details' do |req, res|
    con = Mysql.new(dbHost, dbUser, dbPass, 'bookinfo_db', dbPort)
    rs = con.query('SELECt * FROM books WHERE BookID=1')

    paperback = "default"
    publisher = "default"
    language = "default"
    isbnA = "default"
    isbnB = "default"
    rs.each_hash do |row|
        paperback = row["Paperback"]
        publisher = row["Publisher"]
        language = row["Language"]
        isbnA = row["ISBN_10"]
        isbnB = row["ISBN_13"]
    end
    details_resp = '
    <h4 class="text-center text-primary">Book Details</h4>
    <dl>
    <dt>Paperback:</dt>' + paperback + '
    <dt>Publisher:</dt>' + publisher + '
    <dt>Language:</dt>' + language + '
    <dt>ISBN-10:</dt>' + isbnA + '
    <dt>ISBN-13:</dt>' + isbnB + '
    </dl>
    '
    res.body = details_resp
    res['Content-Type'] = 'text/html'
end

server.mount_proc '/' do |req, res|
  res.body = '
    <html>
    <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!-- Latest compiled and minified CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">

    <!-- Optional theme -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap-theme.min.css">

    <!-- Latest compiled and minified JavaScript -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.4/jquery.min.js"></script>

    <!-- Latest compiled and minified JavaScript -->
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>

    </head>
    <title>Book details service</title>
    <body>
    <p><h2>Hello! This is the book details service. My content is</h2></p>
    <div>%s</div>
    </body>
    </html>
  ' % [details_resp]
  res['Content-Type'] = 'text/html'
end

server.start
