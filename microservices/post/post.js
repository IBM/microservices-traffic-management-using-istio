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
var request = require('request');
var mysql = require('mysql');

port = parseInt(process.argv[2]);

var hostName = process.env.MYSQL_DB_HOST;
var portNumber = process.env.MYSQL_DB_PORT;
var username = process.env.MYSQL_DB_USER;
var password = process.env.MYSQL_DB_PASSWORD;

var slackWebHookURL = process.env.SLACK_WEBHOOK_URL


var form = '<br>' +
            '<form action="/postReview" method="post">' +
            'Reviewer:<br>' +
            '<input type="text" name="reviewer" value="Your name here" maxlength="40" required><br><br>' +
            'Rating: (1-5)<br>' +
            '<input type="number" name="rating" size="1" min="1" max="5" required><br><br>' +
            'Review:<br>' +
            '<textarea name="review" rows="3" cols="100" wrap="soft" maxlength="1000" required></textarea><br><br>' +
            '<input type="submit" value="Submit"><br><br><br>' +
            '<a href="deleteReviews">This link instantly deletes all the reviews from the database.</a>' +
            '</form>';

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
        '<div>' + form + '</div>' +
        '</body>' +
        '</html>',
        {"Content-type": "text/html"})
})

dispatcher.onGet("/post", function(req, res) {
    res.writeHead(200)
    res.end(form)
})

dispatcher.onGet("/deleteReviews", function(req, res) {
    res.writeHead(302, {'Location': '/productpage'}, {'Content-Type': 'text/plain'})

    var connection = mysql.createConnection({
        host: hostName,
        port: portNumber,
        user: username,
        password: password,
        database : 'bookinfo_db'
    });

    connection.connect();

    SQLstatement = "DELETE FROM reviews"

    connection.query(SQLstatement, function (error, fields) {
        if (error) throw error;
        console.log("Reviews deleted.")
    });

    connection.end();
    res.end()
})

dispatcher.onPost("/postReview", function(req, res) {
    // https://hooks.slack.com/services/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
    res.writeHead(302, {'Location': '/productpage'}, {'Content-Type': 'text/plain'})

    var reviewer = req.params.reviewer
    var review = req.params.review
    var rating = req.params.rating
    var message = "A review from " + reviewer + " has been posted with a rating of " + rating + " -- _'" + review + "'_"
    var json = { text: message }

    var connection = mysql.createConnection({
        host: hostName,
        port: portNumber,
        user: username,
        password: password,
        database : 'bookinfo_db'
    });

    connection.connect();

    SQLstatement = "INSERT INTO reviews (BookID,Reviewer,Review,Rating) VALUES (\"1\",\"" + reviewer + "\",\""+ review + "\",\"" + rating + "\")"

    connection.query(SQLstatement, function (error, fields) {
        if (error) throw error;
        console.log("1 record inserted")
    });


    request({
        url: slackWebHookURL,
        method: "POST",
        json: true,   // <--Very important!!!
        body: json
    }, function (error, response, body){
        //console.log(response);
    });

    connection.end();

    res.end()

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
