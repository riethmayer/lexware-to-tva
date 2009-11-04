# Wozu unterschiedliche Brutto-Preise?
# grossPrice1
# und grossPrice2 wie sieht es aus bei massenbestellungen und der prozentuale anteil an gesamtpreisen? wird der preis dann immer pro item ueberschrieben?
# Artikel ist immer nicht gesperrt
#
# oversea pro artikelnummer
# es werden lieferschein und rechnung werden
# lieferschein
# Infoblock:
# Bezugsnummer 1
# test.xml ist lieferschein xml.
# xml vom lieferschein muss mit uebergeben werden
# in der bezugsnummer steht die rechnungs-nummer.
# die nummer an sich muss nicht uebergeben werden.
# belegnummer des auftrags im freifeld
# belegnummer = bezugnummer
# auftragsbest, liefer, rechnung
# rechnung bezieht sich auf liefer
# liefer bezieht sich auf auftrag
# die lsf-config anpassen um die xml-ausgabe des lieferscheins zu erweitern.
# auftragsbestaetigungsnummer wird mit uebergeben
# pro tag eine xml
# nur lieferschein ohne rechnung = Werbung
# bezugsnummer der auftragsbestaetigung
# drei preisgruppen
# privat 100%
# haendler 90% rabatt immer auf die gesamte bestellung
# grosshaendler 80%
# austausch kann auch 0 euro enthalten fuer eine position
# nur 2 faelle: 0 % oder 19%
# wenn ustid angegeben:
# privat in europa
# europaeisch oder ausserhalb eu
# haendler in europa haben ustid fsteuerbar evtl nein aber ustid pflicht
# fsteuerbar = ja => 19% sonst 0% (taxcode)
# was hat prioritaet? 19% oder taxcode?
# SteuerausgabeNBL ist bindend (mit ustid innergemeintlich, steuerfrei ausfuhr fuer ausland)
# steuersatz aus dem artikel (ist bindend)
# umsatzsteuerid = ustid : ist relevant muss uebergebenw erden, wenn der mwst = 0%, ist die ustid mit aufzufuehren.
# ustid immer nur dann angeben, wenn notwendig!
# ausland immer 0%
# wenn nach oesterreich und rechnungsaddresse in deutschland, dann 0% und ustid.
# es muss immer die bezugsnummer die auftragsbestaetigungsnummer sein.
# internetauftraege existieren nicht mehr und sollen ignoriert werden
# Auftraege an TVA fuer die es keine AB gibt, wie finden wir den auftrag dann wieder? Gibt es nur bei Internetbestellungen und ist gliehc unserer Bestellnummer
# Bei geschaeftskunden existiert immer eine AB.
# dispocode bitte edv anrufen und checken
# die rabbatierung : preis veraendert oder gesamtrabatt sonst nix
# es werden nebenleistungen definiert: koennen nebenleistungen von artikeln unterschieden werden? versandkosten duerfen nicht rabbatiert werden.
#
