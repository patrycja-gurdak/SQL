DROP TABLE grupa10 CASCADE;
CREATE TABLE grupa10(
 nr_sekcji INTEGER PRIMARY KEY,
 nazwa_sekcji VARCHAR(50) UNIQUE NOT NULL);

INSERT INTO grupa10(nr_sekcji, nazwa_sekcji) VALUES 
 (1, 'charty dlugowlose'),
 (2, 'charty szorstkowlose'),
 (3, 'charty krotkowlose');

DROP TABLE rasy CASCADE;
CREATE TABLE rasy (
 id_rasy SERIAL PRIMARY KEY, 
 nr_sekcji INTEGER NOT NULL REFERENCES grupa10(nr_sekcji) ON DELETE RESTRICT,
 nazwa_rasy VARCHAR(50) UNIQUE NOT NULL,
 wzorzec INTEGER UNIQUE NOT NULL);

--na podstawie:
--https://www.zkwp.pl/index.php/ct-menu-item-42/2-uncategorised/166-wzorce-ras-gr10
INSERT INTO rasy (nr_sekcji, nazwa_rasy, wzorzec) VALUES
 (1, 'chart afganski', 228),
 (1, 'chart perski', 269),
 (1, 'chart rosyjski borzoj', 193),
 (2, 'wilczarz irlandzki', 160),
 (2, 'chart szkocki', 164),
 (3, 'chart hiszpanski', 285),
 (3, 'greyhound', 158),
 (3, 'whippet', 162),
 (3, 'charcik wloski', 200),
 (3, 'chart wegierski', 240),
 (3, 'chart afrykanski - Azawakh', 307),
 (3, 'chart arabski - Sloughi', 188),
 (3, 'chart polski', 333);

DROP TABLE hodowcy CASCADE;
CREATE TABLE hodowcy(
 id_hodowcy SERIAL PRIMARY KEY,
 imie VARCHAR(50) NOT NULL,
 nazwisko VARCHAR(50) NOT NULL,
 adres VARCHAR(100) NOT NULL,
 UNIQUE(imie, nazwisko, adres));

DROP TABLE hodowle CASCADE;
CREATE TABLE hodowle(
 id_hodowli SERIAL PRIMARY KEY, 
 nazwa VARCHAR(100) UNIQUE NOT NULL,
 wlasciciel INTEGER NOT NULL REFERENCES hodowcy(id_hodowcy) ON DELETE CASCADE);

DROP TABLE psy CASCADE;
CREATE TABLE psy (
 id_psa SERIAL PRIMARY KEY,
 imie_psa VARCHAR(100) UNIQUE, 
 plec TEXT CHECK(plec IN('pies','suka')),
 rasa INTEGER NOT NULL REFERENCES rasy(id_rasy) ON DELETE RESTRICT, 
 data_urodzenia DATE NOT NULL CHECK(data_urodzenia <= NOW()), 
 hodowla INTEGER NOT NULL REFERENCES hodowle(id_hodowli) ON DELETE CASCADE);

DROP TABLE klasy CASCADE;
CREATE TABLE klasy(
 id_klasy SERIAL PRIMARY KEY,
 nazwa_klasy VARCHAR(50) NOT NULL, 
 wiek_od INTEGER,
 wiek_do INTEGER);

INSERT INTO klasy(nazwa_klasy, wiek_od, wiek_do) VALUES
 ('klasa mlodszych szczeniat', 4, 6),
 ('klasa szczeniat', 6, 9),
 ('klasa mlodziezy', 9, 18),
 ('klasa posrednia', 15, 24),
 ('klasa otwarta', 15, NULL),
 ('klasa weteranow', 96, NULL);

DROP TABLE rangi CASCADE;
CREATE TABLE rangi(
 id_rangi SERIAL PRIMARY KEY,
 ranga VARCHAR(50) NOT NULL);

INSERT INTO rangi(ranga) VALUES('krajowa'), ('miedzynarodowa');

DROP TABLE wystawy CASCADE;
CREATE TABLE wystawy(
 id_wystawy SERIAL PRIMARY KEY,
 data_wystawy DATE NOT NULL CHECK(data_wystawy <= NOW()),
 miasto VARCHAR(50) NOT NULL,
 ranga INTEGER NOT NULL REFERENCES rangi(id_rangi) ON DELETE RESTRICT); 


DROP TABLE nagrody CASCADE;
CREATE TABLE nagrody(
 id_nagrody SERIAL PRIMARY KEY,
 pies INTEGER NOT NULL REFERENCES psy(id_psa) ON DELETE CASCADE,
 wystawa INTEGER NOT NULL REFERENCES wystawy(id_wystawy) ON DELETE CASCADE, 
 klasa INTEGER NOT NULL REFERENCES klasy(id_klasy) ON DELETE RESTRICT,
 tytul VARCHAR(30) NOT NULL);

--trigger sprawdzajacy, przed dodaniem nagrody, czy pies w czasie trwania wystawy byl w odpowiednim wieku dla klasy swojej nagrody
CREATE OR REPLACE FUNCTION sprawdz_wiek() RETURNS TRIGGER AS $$
DECLARE
	wiek INTEGER;
	data_wystawy DATE;
	data_urodzenia DATE;
	dolna_granica INT;
	gorna_granica INT;
	
BEGIN
	SELECT wystawy.data_wystawy INTO data_wystawy FROM wystawy WHERE id_wystawy = NEW.wystawa;
	SELECT psy.data_urodzenia INTO data_urodzenia FROM psy WHERE id_psa = NEW.pies;
	SELECT wiek_od, wiek_do INTO dolna_granica, gorna_granica FROM klasy WHERE id_klasy = NEW.klasa;

	wiek:= extract(year from age(data_wystawy, data_urodzenia))*12 + extract(month from age(data_wystawy, data_urodzenia)) ;
	
	IF wiek < dolna_granica OR wiek > gorna_granica THEN
		RAISE EXCEPTION 'Nieodpowiedni wiek psa dla tej klasy nagrody!';
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER sprawdz_wiek_trigger ON nagrody CASCADE;
CREATE TRIGGER sprawdz_wiek_trigger BEFORE INSERT OR UPDATE ON nagrody
	FOR EACH ROW EXECUTE PROCEDURE sprawdz_wiek();


--dostepne sa 2 tytuly nagrod "CWC" i "CACIB", na wystawie miedzynarodowej mozna otrzymac oba te tytuly, a na krajowej tylko "CWC"
--trigger ponizej sprawdza czy przy dodawaniu nagrody jej tytul zgadza sie z ranga wystawy
CREATE OR REPLACE FUNCTION sprawdz_tytul() RETURNS TRIGGER AS $$
DECLARE
	nr_rangi INTEGER;
	ranga TEXT;
	
BEGIN
	SELECT wystawy.ranga INTO nr_rangi FROM wystawy WHERE id_wystawy = NEW.wystawa;
	SELECT rangi.ranga INTO ranga FROM rangi WHERE id_rangi = nr_rangi;
	
	
	IF NEW.tytul = 'CWC' THEN
		IF ranga NOT IN ('krajowa','miedzynarodowa') THEN 
			RAISE EXCEPTION 'Tytulu CWC nie mozna zdobyc na wystawie o randze %!', ranga;
		END IF;
	END IF;

	IF NEW.tytul = 'CACIB' THEN
		IF ranga <> 'miedzynarodowa' THEN
			RAISE EXCEPTION 'Tytulu CACIB nie mozna zdobyc na wystawie o randze %!', ranga;
		END IF;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER sprawdz_tytul_trigger ON nagrody CASCADE;
CREATE TRIGGER sprawdz_tytul_trigger BEFORE INSERT OR UPDATE ON nagrody
	FOR EACH ROW EXECUTE PROCEDURE sprawdz_tytul();


-- na danej wystawie, w danej klasie, z danej rasy nagrode moze otrzymac tylko 1 pies
-- trigger sprawdza ten warunek przy dodawaniu nowej nagrody
CREATE OR REPLACE FUNCTION sprawdz_czy_jedyny() RETURNS TRIGGER AS $$
DECLARE
	nowa_rasa INTEGER;
	
BEGIN
	SELECT psy.rasa INTO nowa_rasa FROM psy WHERE id_psa = NEW.pies;	

	IF EXISTS (SELECT * FROM (SELECT psy.rasa, klasa, wystawa FROM psy JOIN nagrody ON(id_psa=pies)) AS t WHERE t.rasa=nowa_rasa AND t.klasa=NEW.klasa AND t.wystawa = NEW.wystawa) THEN
		RAISE EXCEPTION 'Istnieje juz pies tej rasy, w tej klasie, ktory otrzymal nagrode na tej wystawie!';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER sprawdz_czy_jedyny_trigger ON nagrody CASCADE;
CREATE TRIGGER sprawdz_czy_jedyny_trigger BEFORE INSERT OR UPDATE ON nagrody
	FOR EACH ROW EXECUTE PROCEDURE sprawdz_czy_jedyny();


DROP VIEW widok_psy; 
CREATE VIEW widok_psy AS
	SELECT id_psa, imie_psa, nr_sekcji, nazwa_rasy AS "rasa", plec,
extract(year from age(NOW(), data_urodzenia))*12 + extract(month from age(NOW(), data_urodzenia)) AS "wiek (miesiace)",
data_urodzenia, nazwa AS "nazwa hodowli", imie || ' ' || nazwisko AS "wlasciciel", adres AS "adres hodowcy"
	FROM psy JOIN rasy ON (id_rasy = rasa) JOIN hodowle ON(id_hodowli = hodowla) JOIN hodowcy ON(id_hodowcy = wlasciciel);

DROP VIEW widok_nagrody; 
CREATE VIEW widok_nagrody AS
	SELECT id_nagrody, imie_psa, data_wystawy, miasto, nazwa_klasy AS "nazwa klasy", tytul
	FROM nagrody JOIN psy ON (pies = id_psa) JOIN wystawy ON(id_wystawy = wystawa) JOIN klasy ON(klasa = id_klasy);

--widok pomocniczy, zlicza ile nagrod danego typu posiada kazdy pies, na razie krotki dla tych samych psow sie powtarzaja i nie sa scalone
DROP VIEW widok_ile_nagrod_0; 
CREATE VIEW widok_ile_nagrod_0 AS
	SELECT id_psa, imie_psa, nazwa AS "nazwa hodowli", count(CASE WHEN tytul = 'CWC' THEN 1 ELSE NULL END) AS nagrody_CWC, count(CASE WHEN tytul = 'CACIB' THEN 1 ELSE NULL END) AS nagrody_CACIB
	FROM psy LEFT JOIN nagrody ON(id_psa = pies) JOIN hodowle ON(hodowla = id_hodowli)
	GROUP BY id_psa, imie_psa, nazwa, tytul;

--krotki dla tych samych psow scalone
DROP VIEW widok_ile_nagrod;
CREATE VIEW widok_ile_nagrod AS
	SELECT id_psa, imie_psa, "nazwa hodowli", MAX(nagrody_CWC) AS nagrody_CWC, MAX(nagrody_CACIB) AS nagrody_CACIB
	FROM widok_ile_nagrod_0
	GROUP BY id_psa, imie_psa, "nazwa hodowli";
