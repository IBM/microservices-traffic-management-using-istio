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

INSERT INTO books (BookID,BookName, Description, Paperback, Publisher, Language,ISBN_10,ISBN_13) VALUES ('1','The Comedy of Errors', 'Shakespeare\'s The Comedy of Errors is the slapstick farce of his youth. In it, the lost twin sons of the old merchant Egeon—both named Antipholus—find themselves in Ephesus, without either one even knowing of the other\'s existence. Meanwhile, Egeon has arrived in search of the son he thinks is still alive—and has been sentenced to death for the \"crime\" of being from Syracuse.', '272 pages', 'Simon and Schuster', 'English','0743484886','978-0743484886');


INSERT INTO reviews (ReviewID, BookID, Reviewer, Review, Rating) VALUES ('1','1', 'John Doe', 'Comedy of twin-switching','4');
INSERT INTO reviews (ReviewID, BookID, Reviewer, Review, Rating) VALUES ('2','1', 'Jane Smith', 'Shakespeare\'s 1st Smash!','5');
