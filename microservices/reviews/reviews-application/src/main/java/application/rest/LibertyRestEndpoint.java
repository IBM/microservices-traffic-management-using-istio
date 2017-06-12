/*******************************************************************************
 * Copyright (c) 2017 Istio Authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *******************************************************************************/
package application.rest;
import java.io.StringReader;
import java.sql.*;

import javax.annotation.Resource;
import javax.json.Json;
import javax.json.JsonObject;
import javax.json.JsonObjectBuilder;
import javax.json.JsonReader;
import javax.sql.DataSource;
import javax.ws.rs.ApplicationPath;
import javax.ws.rs.CookieParam;
import javax.ws.rs.GET;
import javax.ws.rs.HeaderParam;
import javax.ws.rs.Path;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientBuilder;
import javax.ws.rs.client.Invocation;
import javax.ws.rs.client.Invocation.Builder;
import javax.ws.rs.client.ResponseProcessingException;
import javax.ws.rs.client.WebTarget;
import javax.ws.rs.core.Application;
import javax.ws.rs.core.Cookie;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

@Path("/")
public class LibertyRestEndpoint extends Application {

    private final static Boolean ratings_enabled = Boolean.valueOf(System.getenv("ENABLE_RATINGS"));
    private final static String star_color = System.getenv("STAR_COLOR") == null ? "black" : System.getenv("STAR_COLOR");
    private final static String ratings_service = "http://ratings:9080/ratings";
    private final static String dbHost = System.getenv("MYSQL_DB_HOST");
    private final static String dbPort = System.getenv("MYSQL_DB_PORT");
    private final static String dbUser = System.getenv("MYSQL_DB_USER");
    private final static String dbPassword = System.getenv("MYSQL_DB_PASSWORD");
    

    @Resource(lookup="jdbc/mydb")
    private DataSource dataSource;
    
    private final static String review_resp = ""+
      "<blockquote>"+
      "<p>"+
      "%s"+
      "</p> <small>%s <cite>Affiliation1</cite></small>"+
      "%s"+
      "</blockquote>"+
      "<blockquote>"+
      "<p>"+
      "%s"+
      "</p> <small>%s <cite>Affiliation2</cite></small>"+
      "%s"+
      "</blockquote>";

    private JsonObject getRatings(Cookie user, String xreq, String xtraceid, String xspanid,
                                  String xparentspanid, String xsampled, String xflags, String xotspan){
      ClientBuilder cb = ClientBuilder.newBuilder();
      String timeout = star_color.equals("black") ? "10000" : "2500";
      cb.property("com.ibm.ws.jaxrs.client.connection.timeout", timeout);
      cb.property("com.ibm.ws.jaxrs.client.receive.timeout", timeout);
      Client client = cb.build();
      WebTarget ratingsTarget = client.target(ratings_service);
      Invocation.Builder builder = ratingsTarget.request(MediaType.APPLICATION_JSON);
      if(xreq!=null) {
        builder.header("x-request-id",xreq);
      }
      if(xtraceid!=null) {
        builder.header("x-b3-traceid",xtraceid);
      }
      if(xspanid!=null) {
        builder.header("x-b3-spanid",xspanid);
      }
      if(xparentspanid!=null) {
        builder.header("x-b3-parentspanid",xparentspanid);
      }
      if(xsampled!=null) {
        builder.header("x-b3-sampled",xsampled);
      }
      if(xflags!=null) {
        builder.header("x-b3-flags",xflags);
      }
      if(xotspan!=null) {
        builder.header("x-ot-span-context",xotspan);
      }
      if(user!=null) {
        builder.cookie(user);
      }
      Response r = builder.get();
      int statusCode = r.getStatusInfo().getStatusCode();
      if (statusCode == Response.Status.OK.getStatusCode() ) {
        StringReader stringReader = new StringReader(r.readEntity(String.class));
        try (JsonReader jsonReader = Json.createReader(stringReader)) {
           JsonObject j = jsonReader.readObject();
           JsonObjectBuilder jb = Json.createObjectBuilder();
           for(String key : j.keySet()){
             int count = j.getInt(key);
             String stars = "<font color=\""+ star_color +"\">";
             for(int i=0; i<count; i++){
               stars += "<span class=\"glyphicon glyphicon-star\"></span>";
             }
             stars += "</font>";
             if(count<5){
               for(int i=0; i<(5-count); i++){
                 stars += "<span class=\"glyphicon glyphicon-star-empty\"></span>";
               }
             }
             jb.add(key,stars);
           }
           JsonObject result = jb.build();
           return result;
        }
      }else{
        System.out.println("Error: unable to contact "+ratings_service+" got status of "+statusCode);
        return null;
      }
    }

    @GET
    @Path("/health")
    public Response health() {
        return Response.ok().type(MediaType.TEXT_HTML_TYPE).entity("Reviews is healthy").build();
    }

    @GET
    @Path("/reviews")
    public Response bookReviews(@CookieParam("user") Cookie user,
                                @HeaderParam("x-request-id") String xreq,
                                @HeaderParam("x-b3-traceid") String xtraceid,
                                @HeaderParam("x-b3-spanid") String xspanid,
                                @HeaderParam("x-b3-parentspanid") String xparentspanid,
                                @HeaderParam("x-b3-sampled") String xsampled,
                                @HeaderParam("x-b3-flags") String xflags,
                                @HeaderParam("x-ot-span-context") String xotspan) {
      String r1 = "";
      String r2 = "";
      Integer[] reviewID = new Integer[2];
      String[] review = new String[2];
      String[] reviewer = new String[2];
      
      try {
      Class.forName("com.mysql.jdbc.Driver").newInstance();
      String URL = "jdbc:mysql://" + dbHost + ":" + dbPort + "/bookinfo_db" ;
      Connection con = DriverManager.getConnection(URL, dbUser, dbPassword);

      Statement st = con.createStatement();
      String sql = ("SELECT * FROM reviews;");
      ResultSet rs = st.executeQuery(sql);
      
      int count = 0;
      while (rs.next()) { 
       reviewID[count] = rs.getInt("ReviewID");
       review[count] = rs.getString("Review");
       reviewer[count] = rs.getString("Reviewer");
       System.out.println(reviewID[count] + " " + review[count] + " " + reviewer[count]);
       count++;
      }

      con.close();
      }
      catch (Exception ex) {
    	  ex.printStackTrace();
      }
      
      
      if(ratings_enabled){
        JsonObject ratings = getRatings(user, xreq, xtraceid, xspanid, xparentspanid, xsampled, xflags, xotspan);

        if(ratings!=null){
          if(ratings.containsKey("Reviewer1")){
            r1 = ratings.getString("Reviewer1");
          }
          if(ratings.containsKey("Reviewer2")){
            r2 = ratings.getString("Reviewer2");
          }
        }else{
            // return Response.serverError().build();
            r1 = r2 = "<span class=\"bg-warning\">product ratings not available</span>";
        }
      }
      String replyBody = String.format(review_resp,review[0],reviewer[0],r1,review[1],reviewer[1],r2);
      return Response.ok().type(MediaType.TEXT_HTML_TYPE).entity(replyBody).build();
    }

    private final static String index = ""+
    "<html>"+
    "<head>"+
    "<meta charset=\"utf-8\">"+
    "<meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\">"+
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"+
    "<!-- Latest compiled and minified CSS -->"+
    "<link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css\">"+
    "<!-- Optional theme -->"+
    "<link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap-theme.min.css\">"+
    "<!-- Latest compiled and minified JavaScript -->"+
    "<script src=\"https://ajax.googleapis.com/ajax/libs/jquery/2.1.4/jquery.min.js\"></script>"+
    "<!-- Latest compiled and minified JavaScript -->"+
    "<script src=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js\"></script>"+
    "</head>"+
    "<title>Book reviews service</title>"+
    "<body>"+
    "<p><h2>Hello! This is the book reviews service. My content is</h2></p>"+
    "<div>%s</div>"+
    "<p>Ratings service enabled? %s</p>"+
    "<p>Star color: %s </p>"+
    "</body>"+
    "</html>";

    @GET
    @Path("/")
    public String getDefault(){
      return String.format(index,review_resp,ratings_enabled,star_color);
    }

}
