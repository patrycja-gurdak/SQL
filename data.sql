--hodowcy
INSERT INTO hodowcy (imie, nazwisko, adres) VALUES
('Edward', 'Kowalski', 'ul. Zamkowa 13, Wroclaw'), 
('Tomasz', 'Nowak', 'ul. Mickiewicza 132/5, Warszawa'), 
('Karol', 'Choinka', 'ul. Herubinowa 30, Krakow'),
('Piotr', 'Burak', 'ul. Kwiatowa 98, Katowice'), 
('Eustachy', 'Krakowiak', 'ul. Sienkiewicza 5, Rawicz');


--hodowle
INSERT INTO hodowle (nazwa, wlasciciel) VALUES
('Minewra',1),('Wenus',1),('Merkury',3), 
('Pluton',4), ('Sol', 5), ('Akwilon',2), 
('Westa',5), ('Ops', 4), ('Faun',5), 
('Luna',5),('Diana',1), ('Mars',2), 
('Junona',3), ('Neptun',2), ('Jowisz', 4), 
('Aurora', 5), ('Ceres', 4), ('Wulkan',3);

--psy
INSERT INTO psy (imie_psa, plec, rasa, data_urodzenia, hodowla) VALUES 
('Pluto', 'pies', 13, '2017-09-11', 15),
('Pimpek', 'pies', 13, '2017-09-11', 15),
('Pusia', 'suka', 13, '2017-09-11', 15),
('Renia', 'suka', 8, '2018-09-13', 2),
('Ron', 'pies', 8, '2018-09-13', 2),
('Ergo', 'pies', 2, '2015-09-20', 3),
('Ezehiel', 'pies', 2, '2015-09-20', 3),
('Edek', 'pies', 2, '2015-09-20', 3),
('Eliza', 'suka', 2, '2015-09-20', 5),
('Edmund', 'pies', 2, '2015-09-20', 5),
('Bob', 'pies', 1, '2015-09-30', 7),
('Bulba', 'suka', 1, '2015-09-30', 7),
('Kira', 'suka', 6, '2016-10-03', 9),
('Kulka', 'suka', 6, '2016-10-03', 9),
('Kuzyn', 'pies', 6, '2016-10-03', 9),
('Alan', 'pies', 3, '2019-05-05', 13),
('Ala', 'suka', 3, '2019-05-05', 13),
('As', 'pies', 3, '2019-05-05', 13),
('Przemek', 'suka', 3, '2020-01-07', 13),
('Pablo', 'pies', 3, '2020-01-07', 13);

INSERT INTO wystawy(data_wystawy, miasto, ranga) VALUES
('2019-11-20', 'Wroclaw', 1),
('2019-10-13', 'Katowice', 2),
('2019-05-31', 'Walbrzych', 1),
('2020-01-13', 'Krakow', 2);

INSERT INTO nagrody(pies, wystawa, klasa, tytul) VALUES
(11, 1, 5, 'CWC'),
(4, 1, 3, 'CWC'),
(17, 1, 2, 'CWC'),
(17, 2, 1, 'CWC'),
(17, 4, 2, 'CACIB'),
(11, 2, 5, 'CACIB');

--TEST TRIGGERÓW
--ten pies ma teraz 28 miesiecy, a wystawa wydarzyla sie jak miala okolo 26 miesiecy, wiec nie moze dostac nagrody w kategorii malych szczeniat
--INSERT INTO nagrody(pies, wystawa, klasa, tytul) VALUES (1, 1, 1, 'CWC');

--sprobujmy wstawic nagrode o tytule CACIB na wystawie krajowej
--INSERT INTO nagrody(pies, wystawa, klasa, tytul) VALUES (1, 1, 5, 'CACIB');

--dwa psy tej samej rasy, nie moga dostac na tej samej wystawie nagrod w tej samej klasie
--w naszej bazie jest juz nagroda dla psa nr 11, rasy 1, w klasie 5
--INSERT INTO nagrody(pies, wystawa, klasa, tytul) VALUES(12, 1, 5, 'CWC');

