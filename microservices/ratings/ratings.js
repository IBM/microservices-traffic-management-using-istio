// Copyright 2017 Istio Authors
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.

var http = require('http');
var dispatcher = require('httpdispatcher');
var mysql = require('mysql');

port = parseInt(process.argv[2]);

var hostName = process.env.MYSQL_DB_HOST;
var portNumber = process.env.MYSQL_DB_PORT;
var username = process.env.MYSQL_DB_USER;
var password = process.env.MYSQL_DB_PASSWORD;



var first_rating = 0;
var second_rating = 0;
var third_rating = 0;
var fourth_rating = 0;
var fifth_rating = 0;
var ratingsResponse;

dispatcher.onGet("/", function(req, res) {
    res.writeHead(200)
    res.end(
        '<html>' +
        '<head>' +
        '<meta charset="utf-8">' +
        '<meta http-equiv="X-UA-Compatible" content="IE=edge">' +
        '<meta name="viewport" content="width=device-width, initial-scale=1">' +
        '<!-- Latest compiled and minified CSS -->' +
        '<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">' +
        '<!-- Optional theme -->' +
        '<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap-theme.min.css">' +
        '<!-- Latest compiled and minified JavaScript -->' +
        '<script src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.4/jquery.min.js"></script>' +
        '<!-- Latest compiled and minified JavaScript -->' +
        '<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>' +
        '</head>' +
        '<title>Book ratings service</title>' +
        '<body>' +
        '<p><h2>Hello! This is the book ratings service. My content is</h2></p>' +
        '<div>' + JSON.stringify(ratingsResponse) + '</div>' +
        '</body>' +
        '</html>',
        {"Content-type": "text/html"})
})

dispatcher.onGet("/ratings", function(req, res) {
    var connection = mysql.createConnection({
        host: hostName,
        port: portNumber,
        user: username,
        password: password,
        database : 'bookinfo_db'
    });

    var json;
    connection.connect();
    connection.query('SELECT Rating FROM reviews WHERE BookID=1', function (error, results, fields) {
        if (error) throw error;
        if (results[0]) {
            first_rating = results[0].Rating;
        }
        console.log(first_rating);
        if (results[1]) {
            second_rating = results[1].Rating;
        }
        console.log(second_rating);
        if (results[2]) {
            third_rating = results[2].Rating;
        }
        console.log(third_rating);
        if (results[3]) {
            fourth_rating = results[3].Rating;
        }
        console.log(fourth_rating);
        if (results[4]) {
            fifth_rating = results[4].Rating;
        }
        console.log(fifth_rating);
        ratingsResponse = {"Reviewer1": first_rating, "Reviewer2": second_rating, "Reviewer3": third_rating, "Reviewer4": fourth_rating, "Reviewer5": fifth_rating};
        console.log(ratingsResponse);
        json = JSON.stringify(ratingsResponse)
        res.writeHead(200, {"Content-type": "application/json"})
        res.end(json)

    });
    connection.end();
})

dispatcher.onGet("/health", function(req, res) {
    res.writeHead(200, {"Content-type": "text/plain"})
    res.end("Ratings is healthy")
})

function handleRequest(request, response){
    try {
        console.log(request.method + " " + request.url);
        dispatcher.dispatch(request, response);
    } catch(err) {
        console.log(err);
    }
}

var server = http.createServer(handleRequest);

server.listen(port, function(){
    console.log("Server listening on: http://0.0.0.0:%s", port);
});
