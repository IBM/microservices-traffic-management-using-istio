DROP DATABASE IF EXISTS bookinfo_db;
CREATE DATABASE IF NOT EXISTS bookinfo_db;
USE `bookinfo_db`;

CREATE TABLE `books` (
  `BookID` bigint(20) NOT NULL AUTO_INCREMENT,
  `BookName` varchar(20) NOT NULL,
  `Description` varchar(1000),
  `Paperback` varchar(20),
  `Publisher` varchar(50),
  `Language` varchar(20),
  `ISBN_10` varchar(20),
  `ISBN_13` varchar(20),
  PRIMARY KEY (`BookID`)
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=latin1;

CREATE TABLE `reviews` (
  `ReviewID` bigint(20) NOT NULL AUTO_INCREMENT,
  `BookID` int(20) NOT NULL,
  `Reviewer` varchar(40),
  `Review` varchar(1000),
  `Rating` int(20),
  PRIMARY KEY (`ReviewID`,`BookID`)
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=latin1;

INSERT INTO books (BookID,BookName, Description, Paperback, Publisher, Language,ISBN_10,ISBN_13) VALUES ('1','Smart Machines', 'In Smart Machines, John E. Kelly III, director of IBM Research, and Steve Hamm, a writer at IBM and a former business and technology journalist, introduce the fascinating world of "cognitive systems" to general audiences and provide a window into the future of computing. Cognitive systems promise to penetrate complexity and assist people and organizations in better decision making. They can help doctors evaluate and treat patients, augment the ways we see, anticipate major weather events, and contribute to smarter urban planning. Kelly and Hamm\'s comprehensive perspective describes this technology inside and out and explains how it will help us conquer the harnessing and understanding of "big data," one of the major computing challenges facing businesses and governments in the coming decades. Absorbing and impassioned, their book will inspire governments, academics, and the global tech industry to work together to power this exciting wave in innovation.', '160 pages', 'Columbia University Press', 'English','023116856X','978-0231168564');


INSERT INTO reviews (ReviewID, BookID, Reviewer, Review, Rating) VALUES ('1','1', 'John Doe', 'A thought-provoking exposé on IBM\'s efforts in cognitive computing','4');
INSERT INTO reviews (ReviewID, BookID, Reviewer, Review, Rating) VALUES ('2','1', 'Jane Smith', 'Smart Machines will transform healthcare','5');
