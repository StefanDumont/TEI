# Main makefile for TEI P5
# $Id$
LANGUAGE=en
GOOGLEANALYTICS=""
INPUTLANGUAGE=en
DOCUMENTATIONLANGUAGE=en
LATEX=pdflatex
XELATEXFLAGS=--output-driver="xdvipdfmx -V 5" --interaction=batchmode
XELATEX=xelatex 
VERBOSE=
PREFIX=/usr
SOURCETREE=Source
DRIVER=${SOURCETREE}/guidelines-${INPUTLANGUAGE}.xml
ROMA=roma2
ROMAOPTS="--localsource=`pwd`/p5subset.xml"
XSL=/usr/share/xml/tei/stylesheet
XSLP4=/usr/share/xml/teip4/stylesheet
# If you have not installed the Debian packages, uncomment one
# of the next two lines:
#XSL=../Stylesheets/release/tei-xsl/p5
#XSL=http://www.tei-c.org/stylesheet/release/xml/tei
JING=jing
TRANG=trang
SAXON=saxon
SAXON_ARGS=-ext:on
VERSION=`cat VERSION`
UPVERSION=`cat ../VERSION`
ODD2DTD=odds2/odd2dtd.xsl
ODD2RELAX=odds2/odd2relax.xsl
ODD2LITE=odds2/odd2lite.xsl

.PHONY: convert dtds schemas html validate valid test clean dist exemplars

default: validate exemplars test html-web

convert: dtds schemas

check: check.stamp  p5.xml

check.stamp:
	@echo Checking you have running XML tools and Perl before trying to run transform...
	@echo -n Perl: 
	@command -v  perl || exit 1
	@echo -n Java: 
	@command -v  java || exit 1
	@echo -n xmllint: 
	@command -v  xmllint || exit 1
	@echo -n trang: 
	@command -v  ${TRANG} || exit 1
	@echo -n jing: 
	@command -v  ${JING} || exit 1
	@echo -n saxon: 
	@command -v  ${SAXON} || exit 1
	@echo -n roma2: 
	@command -v  roma2 || exit 1
	@echo -n XeLaTeX: 
	@command -v  xelatex || exit 1
	touch check.stamp

p5.xml: ${DRIVER} Source/Specs/*.xml Source/Guidelines/en/*.xml
	xmllint --xinclude --dropdtd --noent ${DRIVER} > p5.xml

dtds: check
	rm -rf DTD
	mkdir DTD
	@echo BUILD: Generate modular DTDs
	${SAXON} ${SAXON_ARGS}  p5.xml ${XSL}/${ODD2DTD} outputDir=DTD 	\
	lang=${LANGUAGE} \
	documentationLanguage=${DOCUMENTATIONLANGUAGE} \
	${VERBOSE}

schemas:check schema-relaxng schema-sch

schema-relaxng:  check
	rm -rf Schema
	mkdir Schema
	@echo BUILD: Generate modular RELAX NG schemas
	${SAXON} ${SAXON_ARGS}  p5.xml  ${XSL}/${ODD2RELAX} outputDir=Schema \
	lang=${LANGUAGE}  \
	${VERBOSE}
	@echo "BUILD: Generate modular RELAX NG (compact) schemas using trang"
	(cd Schema; for i in *rng; do ${TRANG} $$i `basename $$i .rng`.rnc;done)

schema-sch:  check
	@echo BUILD: Extract schema rules to make p5.isosch
	${SAXON} ${SAXON_ARGS}  p5.xml `dirname ${XSL}/${ODD2RELAX}`/extract-isosch.xsl > p5.isosch


html-web: html-web.stamp check.stamp

html-web.stamp:  check
	@echo BUILD: Making HTML Guidelines for language ${LANGUAGE}
	perl -p -e \
		"s+http://www.tei-c.org/release/xml/tei/stylesheet+${XSL}+; \
		 s+/usr/share/xml/tei/stylesheet+${XSL}+;" \
		Utilities/guidelines.xsl.model > Utilities/guidelines.xsl
	mkdir -p Guidelines-web
	rm -rf Guidelines-web-tmp 
	mkdir Guidelines-web-tmp
	mkdir -p Guidelines-web-tmp/${LANGUAGE}/html
	cp odd.css guidelines.css guidelines-print.css Guidelines-web-tmp/${LANGUAGE}/html
	(cd Source/Guidelines/${INPUTLANGUAGE}; tar --exclude .svn -c -f - Images) | (cd Guidelines-web-tmp/${LANGUAGE}/html; tar xf - )
	(cd webnav; tar --exclude .svn -c -f - .) | (cd Guidelines-web-tmp/${LANGUAGE}/html; tar xf - )
	${SAXON} ${SAXON_ARGS}  p5.xml  Utilities/guidelines.xsl  outputDir=Guidelines-web-tmp/${LANGUAGE}/html \
		displayMode=both \
		pageLayout=CSS \
	        lang=${LANGUAGE} \
	        doclang=${LANGUAGE} \
		googleAnalytics=${GOOGLEANALYTICS} \
	        documentationLanguage=${DOCUMENTATIONLANGUAGE}  ${VERBOSE}
	(cd Guidelines-web-tmp/${LANGUAGE}/html; for i in *.html; do perl -i ../../../Utilities/cleanrnc.pl $$i;done)
	(cd Guidelines-web-tmp/${LANGUAGE}/html; perl -p -i -e 's+/logos/TEI-glow+TEI-glow+' guidelines.css)
	rm -rf Guidelines-web/${LANGUAGE}
	mv Guidelines-web-tmp/${LANGUAGE} Guidelines-web/${LANGUAGE}
	rmdir Guidelines-web-tmp
	touch html-web.stamp

validate-html:
	@echo BUILD: Validate HTML version of Guidelines
	export CLASSPATH="`locate jing.jar | head -1`";cd Guidelines-web/${LANGUAGE}/html;for i in *.html; do xmllint --noent --dropdtd $$i > z_$$i; done;ant -f ../../../validatehtml.xml;rm z_*

teiwebsiteguidelines:
	@echo BUILD: make HTML version of Guidelines just for TEI web site
	rm -rf teiwebsiteguidelines.zip Guidelines-web
	curl -s http://www.tei-c.org/index.xml | sed 's/content="text\/html"/content="text\/html; charset=utf-8"/' | xmllint --html --noent --dropdtd --xmlout - > Utilities/teic-index.xml
	rm -f html-web.stamp;make GOOGLEANALYTICS=UA-4372657-1 html-web
	rm html-web.stamp;make GOOGLEANALYTICS=UA-4372657-1 LANGUAGE=es DOCUMENTATIONLANGUAGE=es html-web
	rm html-web.stamp;make GOOGLEANALYTICS=UA-4372657-1 LANGUAGE=de DOCUMENTATIONLANGUAGE=de html-web
	rm html-web.stamp;make GOOGLEANALYTICS=UA-4372657-1 LANGUAGE=ja DOCUMENTATIONLANGUAGE=ja html-web
	rm html-web.stamp;make GOOGLEANALYTICS=UA-4372657-1 LANGUAGE=fr DOCUMENTATIONLANGUAGE=fr html-web
	rm html-web.stamp;make GOOGLEANALYTICS=UA-4372657-1 LANGUAGE=it DOCUMENTATIONLANGUAGE=it html-web
	rm html-web.stamp;make GOOGLEANALYTICS=UA-4372657-1 LANGUAGE=ko DOCUMENTATIONLANGUAGE=ko html-web
	rm html-web.stamp;make GOOGLEANALYTICS=UA-4372657-1 LANGUAGE=zh-TW DOCUMENTATIONLANGUAGE=zh-TW html-web
	(cd Guidelines-web; zip -r -q ../teiwebsiteguidelines.zip . ) 
	rm Utilities/teic-index.xml

pdf: pdf.stamp

fontcheck:
	xelatex --interaction=batchmode Utilities/fonttest 
	if [ -f "missfont.log" ]  ; then  \
	  perl -p -i -e 's/(.*Minion)/%\1/;s/(.*Myriad)/%\1/' Utilities/guidelines.xsl ;\
	  echo "========================="; \
	  echo "Note: you do not have Minion or Myriad fonts installed, reverting to Computer Modern " ;\
	  echo "========================="; \
	fi
	rm -f fonttest.*

pdf.stamp: check 
	@echo BUILD: build Lite version of Guidelines
	${SAXON} ${SAXON_ARGS}  -o:Guidelines.xml p5.xml  ${XSL}/${ODD2LITE} displayMode=rnc lang=${LANGUAGE} \
	        doclang=${DOCUMENTATIONLANGUAGE} \
	        documentationLanguage=${DOCUMENTATIONLANGUAGE}	${VERBOSE}
	@echo BUILD: build LaTeX version of Guidelines from Lite
	perl -p -e \
		"s+http://www.tei-c.org/release/xml/tei/stylesheet+${XSL}+; \
		 s+/usr/share/xml/tei/stylesheet+${XSL}+;" \
		Utilities/guidelines-latex.xsl > Utilities/guidelines.xsl
	@echo BUILD: check XeLaTeX system works locally
	${SAXON} ${SAXON_ARGS}  Guidelines.xml Utilities/guidelines.xsl > Guidelines.tex
	rm -f Utilities/guidelines.xsl
	for i in Guidelines-REF*tex; \
	  do \
	     perl Utilities/rewrapRNC-in-TeX.pl <$$i>$$i.new; \
		echo NOTE: diff $$i.new $$i; \
		diff $$i.new $$i; \
		mv $$i.new $$i; \
	done
	@echo BUILD: build PDF version of Guidelines from LaTeX using XeLaTeX
	@echo Make sure you have Junicode, Arphic and Mincho fonts installed 
	echo '*' | ${XELATEX}  Guidelines
	(echo '*' | ${XELATEX} ${XELATEXFLAGS} Guidelines) 2> pdfbuild.log 1> pdfbuild.log
	grep -v "Failed to convert input string to UTF16" pdfbuild.log
	makeindex -s p5.ist Guidelines 
	(echo '*' | ${XELATEX} ${XELATEXFLAGS} Guidelines) 2> pdfbuild.log 1> pdfbuild.log
	grep -v "Failed to convert input string to UTF16" pdfbuild.log
	(echo '*' | ${XELATEX} ${XELATEXFLAGS} Guidelines) 2> pdfbuild.log 1> pdfbuild.log
	grep -v "Failed to convert input string to UTF16" pdfbuild.log
	rm pdfbuild.log
	rm Guidelines.xml
	for i in Guidelines*aux; do perl -p -i -e 's/.*zf@fam.*//' $$i; done
	touch pdf.stamp

chapterpdfs: check
	for i in `grep "\\include{" Guidelines.tex | sed 's/.*{\(.*\)}.*/\\1/'`; \
	do echo PDF for chapter $$i; \
	echo  $$i | ${XELATEX} Guidelines; \
	echo  $$i | ${XELATEX} Guidelines ; \
	mv Guidelines.pdf $$i.pdf; \
	perl -p -i -e 's/.*zf@fam.*//' $$i.aux; \
	done

validate: dtds schemas oddschema exampleschema valid 

#The following line commented out in 10605 by MDH. Restored 2012-10-26 to see if it was the source of 2.2.0 release problems.
valid: jing_version=$(wordlist 1,3,$(shell jing))
valid: check
#	@echo BUILD: Check validity with jing
#	@echo ${jing_version}
#	We have discovered that jing reports 3-letter language codes
#	from ISO 639-2 as illegal values of xml:lang= even though
#	they are perfectly valid per RFC 3066. We have submitted a
#	bug report, and for now just throw away those error messages
#	with grep -v. Note that we discard *all* such messages, even
#	though fewer than 500 of the 17,576 possible combinations
#	(i.e. < 3%) are valid codes.
#	$(JING) -t p5odds.rng p5.xml 
#
	@echo BUILD: Check validity with nvdl/jing, including all examples with feasible validity
	./run-onvdl p5.nvdl p5.xml 
	@echo BUILD: Check validity with rnv if we have it
	-command -v  rnv && rnv -v p5odds.rnc p5.xml
	@echo BUILD: Check full validity of relevant examples with nvdl
	${SAXON} p5.xml Utilities/extractegXML.xsl > v.body
	echo "<!DOCTYPE p [" > v.header
	(cd valid; ls | perl -p -e  "s+(.*)+<\!ENTITY \1 SYSTEM \"valid/\1\">+") >> v.header
	echo "]>" >> v.header
	cat v.header v.body > v.xml
	./run-onvdl  p5valid.nvdl  v.xml
	rm v.body v.header
	@echo BUILD: Check validity with Schematron
	${SAXON} ${SAXON_ARGS}  -s:p5.isosch -xsl:Utilities/iso_schematron_message_xslt2.xsl > p5.isosch.xsl
	${SAXON} ${SAXON_ARGS}  -s:p5.xml -xsl:p5.isosch.xsl
	@echo BUILD: Check validity with local XSLT script
	${SAXON} ${SAXON_ARGS}  -s:p5.xml -xsl:Utilities/prevalidator.xsl > Utilities/pointerattributes.xsl
	${SAXON} ${SAXON_ARGS}  -o:ValidatorLog.xml -s:p5.xml -xsl:Utilities/validator.xsl 
	(grep -q "<ERROR>" ValidatorLog.xml;if [ $$? -eq 1 ] ; then echo No problems ; else echo "Oh dear me. ERROR found"; grep "<ERROR>" ValidatorLog.xml;false; fi)
	diff ValidatorLog.xml expected-results/ValidatorLog.xml
	cat ValidatorLog.xml
	rm ValidatorLog.xml Utilities/pointerattributes.xsl 
	#@echo BUILD: Check validity with xmllint
	#xmllint  --relaxng p5odds.rng --noent --xinclude --noout p5.xml
	@echo BUILD: Check for places with no examples
	${SAXON} -s:p5.xml -xsl:Utilities/listspecwithnoexample.xsl 
	@echo BUILD: do graphics files exist
	${SAXON} -s:p5.xml -xsl:Utilities/listgraphics.xsl | sh

#test: debversion
test: p5subset.xml
	@echo BUILD Run test cases for P5
	(cd Test; make XSL=${XSL})

exemplars:  p5subset.xml
	@echo BUILD TEI Exemplars
	(cd Exemplars; make XSL=${XSL} PREFIX=${PREFIX})

oddschema: p5odds.rng 

p5odds.rng: p5subset.xml p5odds.odd
	@echo Checking you have a running ${ROMA} before trying to make p5odds.rng ...
	command -v  ${ROMA} || exit 1
	${ROMA} ${ROMAOPTS} --nodtd --noxsd --xsl=${XSL}/ p5odds.odd .

exampleschema:  p5odds-examples.rng p5subset.xml
p5odds-examples.rng: p5subset.xml p5odds-examples.odd
	@echo Checking you have a running ${ROMA} before trying to make p5odds-examples.rng ...
	command -v  ${ROMA} || exit 1
	${ROMA}  ${ROMAOPTS} --nodtd --noxsd --xsl=${XSL}/ p5odds-examples.odd . 

p5subset.xml: check
	@echo BUILD make subset of P5 with just the module/element/class/macro Spec elements
	${SAXON} ${SAXON_ARGS}  -o:p5subset.xml  p5.xml Utilities/subset.xsl || echo "failed to extract subset from p5.xml." 
	touch p5subset.xml

p5subset.json: p5subset.xml
	${SAXON} -o:p5subset.json p5subset.xml ${XSL}/odds2/odd2json.xsl callback=

p5subset.js: p5subset.xml
	${SAXON} -o:p5subset.js p5subset.xml ${XSL}/odds2/odd2json.xsl callback=teijs

dist-source.stamp: check p5subset.json p5subset.js oddschema exampleschema
	${SAXON} -s:p5subset.xml -xsl:${XSL}/odds2/odd2xslstripspace.xsl > stripspace.xsl.model
	${SAXON} -s:p5subset.xml -xsl:Utilities/listofattributes.xsl > p5attlist.txt
	@echo BUILD: Make distribution directory for source
	rm -rf release/tei-p5-source*
	mkdir -p release/tei-p5-source/share/xml/tei/odd
	tar -c -f - --exclude "*~" --exclude .svn 	\
	p5subset.xml \
	p5subset.json \
	p5subset.js \
	stripspace.xsl.model \
	p5attlist.txt \
	Makefile \
	ReleaseNotes  \
	Source \
	Utilities   \
	VERSION  \
	Exemplars/Makefile  \
	Exemplars/relax*  \
	Exemplars/math*  \
	Exemplars/svg*  \
	fasc-head.xml \
	fasc-tail.xml \
	p5.nvdl \
	p5odds.odd \
	p5odds.rng \
	p5odds.rnc \
	p5odds-examples.odd \
	p5odds-examples.rng \
	p5odds-examples.rnc \
	relax.rng \
	schematron.rng \
	iso-schematron.rng \
	p5sch.xsl \
	schematron1-5.rnc \
	run-onvdl \
	*.css \
	webnav \
	xhtml.rnc \
	| (cd release/tei-p5-source/share/xml/tei/odd; tar xf - )
	touch dist-source.stamp
	rm p5subset.json p5subset.js p5attlist.txt stripspace.xsl.model

dist-schema.stamp:check  schemas dtds oddschema exampleschema
	@echo BUILD: Make distribution directory for schema
	rm -rf release/tei-p5-schema*
	mkdir -p release/tei-p5-schema/share/xml/tei/schema/dtd
	mkdir -p release/tei-p5-schema/share/xml/tei/schema/relaxng
	(cd DTD; tar --exclude .svn -c -f - .) \
	| (cd release/tei-p5-schema/share/xml/tei/schema/dtd; tar xf - )
	cp catalog.p5 release/tei-p5-schema/share/xml/tei/schema/catalog.xml
	(cd Schema; tar --exclude .svn -c -f - .) \
	| (cd release/tei-p5-schema/share/xml/tei/schema/relaxng; tar xf - )
	touch dist-schema.stamp

dist-doc.stamp:  check
	@echo BUILD: Make distribution directory for doc
	rm -rf release/tei-p5-doc*
	mkdir -p release/tei-p5-doc/share/doc/tei-p5-doc
	cp VERSION release/tei-p5-doc/share/doc/tei-p5-doc
	@echo BUILD: Make web pages for release notes
	for i in ReleaseNotes/readme*xml; \
	do  teitohtml --css=en/html/guidelines.css --profile=readme $$i  \
		./release/tei-p5-doc/share/doc/tei-p5-doc/`basename $$i .xml`.html; \
	done
	@echo BUILD: Make web guidelines in all supported languages
	make html-web
	rm html-web.stamp;make LANGUAGE=es DOCUMENTATIONLANGUAGE=es html-web
	rm html-web.stamp;make LANGUAGE=de DOCUMENTATIONLANGUAGE=de html-web
	rm html-web.stamp;make LANGUAGE=ja DOCUMENTATIONLANGUAGE=ja html-web
	rm html-web.stamp;make LANGUAGE=ko DOCUMENTATIONLANGUAGE=ko html-web
	rm html-web.stamp;make LANGUAGE=fr DOCUMENTATIONLANGUAGE=fr html-web
	rm html-web.stamp;make LANGUAGE=it DOCUMENTATIONLANGUAGE=it html-web
	rm html-web.stamp;make LANGUAGE=zh-TW DOCUMENTATIONLANGUAGE=zh-TW html-web
	(cd Guidelines-web; tar --exclude .svn -c -f - . ) \
	| (cd release/tei-p5-doc/share/doc/tei-p5-doc; tar xf - )
	@echo BUILD: make PDF version of Guidelines
	make pdf
	@echo BUILD: make ePub and Kindle version of Guidelines
	make epub
	make mobi
	cp Guidelines.pdf Guidelines.epub release/tei-p5-doc/share/doc/tei-p5-doc/en
	-test -f Guidelines.mobi  && cp Guidelines.mobi release/tei-p5-doc/share/doc/tei-p5-doc/en
	touch dist-doc.stamp

dist-test.stamp: check
	@echo BUILD: Make distribution directory for test
	rm -rf release/tei-p5-test*
	mkdir -p release/tei-p5-test/share/xml/tei
	(cd Test; make clean)
	tar --exclude "*~" --exclude .svn -c -f - Test \
	| (cd release/tei-p5-test/share/xml/tei; tar xf - )
	touch dist-test.stamp

dist-exemplars.stamp: check
	@echo BUILD: Make distribution directory for exemplars
	(cd Exemplars; make dist)
	touch dist-exemplars.stamp

dist-database.stamp: check
	@echo BUILD: Make distribution directory for database
	rm -rf release/tei-p5-database*
	mkdir -p release/tei-p5-database/share/xml/tei/xquery
	(cd Query; tar --exclude .svn --exclude "*~" -c -f - . ) \
	| (cd release/tei-p5-database/share/xml/tei/xquery; tar xf - )
	touch dist-database.stamp

dist-source: dist-source.stamp

dist-schema: dist-schema.stamp

dist-doc: dist-doc.stamp

dist-test: dist-test.stamp

dist-exemplars: dist-exemplars.stamp

dist-database: dist-database.stamp

dist: dist-source dist-schema dist-doc dist-test dist-exemplars dist-database
	@echo BUILD: Make overall zip archive
	rm -rf tei-*.zip release/xml release/doc
	(cd release/tei-p5-database/share; tar cf - . | (cd ../../; tar xf - ))
	(cd release/tei-p5-doc/share; tar cf - . | (cd ../../; tar xf - ))
	(cd release/tei-p5-exemplars/share; tar cf - . | (cd ../../; tar xf - ))
	(cd release/tei-p5-schema/share; tar cf - . | (cd ../../; tar xf - ))
	(cd release/tei-p5-source/share; tar cf - . | (cd ../../; tar xf - ))
	(cd release/tei-p5-test/share; tar cf - . | (cd ../../; tar xf - ))
	(cd release; zip -q -r ../tei-${UPVERSION}.zip xml doc)
	@echo BUILD: Make individual zip archives
	(cd release; rm -rf tei-p5-*-${UPVERSION}.zip)
	(cd release; zip -q -r tei-p5-database-${UPVERSION}.zip tei-p5-database )
	(cd release; zip -q -r tei-p5-doc-${UPVERSION}.zip tei-p5-doc )
	(cd release; zip -q -r tei-p5-exemplars-${UPVERSION}.zip tei-p5-exemplars )
	(cd release; zip -q -r tei-p5-source-${UPVERSION}.zip tei-p5-database )
	(cd release; zip -q -r tei-p5-schema-${UPVERSION}.zip tei-p5-schema )
	(cd release; zip -q -r tei-p5-test-${UPVERSION}.zip tei-p5-test )

debversion:
	sh ./mydch debian-tei-p5-database/debian/changelog
	sh ./mydch debian-tei-p5-doc/debian/changelog
	sh ./mydch debian-tei-p5-exemplars/debian/changelog
	sh ./mydch debian-tei-p5-schema/debian/changelog
	sh ./mydch debian-tei-p5-source/debian/changelog
	sh ./mydch debian-tei-p5-test/debian/changelog

deb: dist debversion
	rm -f tei-p5-*_*deb
	rm -f tei-p5-*_*changes
	rm -f tei-p5-*_*build
	(cd debian-tei-p5-database; debclean;debuild --no-lintian  -nc  -b  -i.svn -I.svn -uc -us)
	(cd debian-tei-p5-doc; debclean;debuild --no-lintian  -nc  -b  -i.svn -I.svn -uc -us)
	(cd debian-tei-p5-exemplars; debclean;debuild --no-lintian  -nc  -b  -i.svn -I.svn -uc -us)
	(cd debian-tei-p5-schema; debclean;debuild --no-lintian  -nc  -b  -i.svn -I.svn -uc -us)
	(cd debian-tei-p5-source; debclean;debuild --no-lintian  -nc  -b  -i.svn -I.svn -uc -us)
	(cd debian-tei-p5-test; debclean;debuild --no-lintian  -nc  -b  -i.svn -I.svn -uc -us)

install-schema: dist-schema
	@echo Making schema release in ${PREFIX}
	(cd release/tei-p5-schema; tar cf - .) | (cd ${PREFIX}; tar xf - )

install-doc: dist-doc
	@echo BUILD: Make doc release in ${PREFIX}
	(cd release/tei-p5-doc; tar cf - .) | (cd ${PREFIX}; tar xf - )

install-source: dist-source
	@echo BUILD: Making source release in ${PREFIX}
	(cd release/tei-p5-source; tar cf - .) | (cd ${PREFIX}; tar xf - )

install-test: dist-test
	@echo BUILD: Making testfiles release in ${PREFIX}
	(cd release/tei-p5-test; tar cf - .) | (cd ${PREFIX}; tar xf - )

install-exemplars: dist-exemplars
	@echo BUILD: Making exemplars release in ${PREFIX}
	(cd release/tei-p5-exemplars; tar cf - share) | (cd ${PREFIX}; tar xf -)

install-database: dist-database
	@echo BUILD: Making database release in ${PREFIX}
	(cd release/tei-p5-database; tar cf - .) | (cd ${PREFIX}; tar xf - )

install: clean install-schema install-doc install-test install-exemplars install-source install-database

epub: epub.stamp

epub.stamp: check
	@echo BUILD: Make epub version of Guidelines
	teitoepub --profiledir=${XSL}/profiles --coverimage=Utilities/cover.jpg --profile=tei p5.xml Guidelines.epub
	java -jar Utilities/epubcheck-1.2.jar Guidelines.epub
	touch epub.stamp

mobi: epub.stamp
	-command -v  kindlegen && kindlegen Guidelines.epub

changelog:
	(LastDate=`head -1 ReleaseNotes/ChangeLog | awk '{print $$1}'`; \
	svn log -v -r 'HEAD:{'$$LastDate'}' | perl ../gnuify-changelog.pl | grep -v "^;" > newchanges)
	mv ReleaseNotes/ChangeLog oldchanges
	cat newchanges oldchanges > ReleaseNotes/ChangeLog
	rm newchanges oldchanges


catalogue: check
	${SAXON} ${SAXON_ARGS}  -o:catalogue.xml p5.xml  Utilities/catalogue.xsl DOCUMENTATIONLANG=${DOCUMENTATIONLANGUAGE}
	teitohtml --profiledir=${XSL}/profiles catalogue.xml catalogue.html
	@echo Made catalogue.html

catalogue-print: check
	${SAXON} ${SAXON_ARGS} p5.xml  Utilities/catalogue-print.xsl DOCUMENTATIONLANG=${DOCUMENTATIONLANGUAGE} | xmllint --format - > catalogue.xml

dependencies:
	@echo to make this thing build under Ubuntu/Debian, here are all the packages you will need:
	@echo	jing
	@echo	msttcorefonts
	@echo	rnv
	@echo	saxon
	@echo	tei-oxygen
	@echo	tei-p5-source
	@echo	tei-p5-xsl
	@echo	tei-p5-xsl2
	@echo	tei-roma
	@echo	tei-xsl-common
	@echo	trang-java
	@echo	ttf-arphic-ukai
	@echo	ttf-arphic-uming 
	@echo	ttf-baekmuk 
	@echo	ttf-junicode
	@echo	ttf-kochi-gothic
	@echo	ttf-kochi-mincho 
	@echo	zip 

clean:
	rm -rf release Guidelines Guidelines-web Schema DTD dtd Split RomaResults *~ 
	rm -rf Guidelines.??? Guidelines-* \
	p5odds-examples.rng  p5odds-examples.rnc \
	p5odds.rng p5odds.rnc \
	*.xsd \
	p5.sch p5.isosch \
	*.isosch.xsl \
	tei-*.zip \
	Test/*.isosch \
	p5subset.xml p5subset.json p5subset.js p5.xml \
	Utilities/guidelines.xsl Utilities-1/guidelines.xsl
	find . -name "semantic.cache" | xargs rm -f
	(cd Test; make clean)
	(cd Exemplars; make clean)
	rm -rf FASC-*
	rm -rf catalogue.* modList
	rm -f       p5.xml
	rm -f       Guidelines.epub
	rm -f       Guidelines.mobi
	rm -f       Test/detest.rnc
	rm -f       Test/detest.rng
	rm -f       Test/detest.dtd
	rm -rf valid v.xml
	rm -f v.body v.header missfont.log 
	rm -f *.stamp
	rm -f tei-p5-*_*deb
	rm -f tei-p5-*_*changes
	rm -f tei-p5-*_*build
	rm -f teiwebsiteguidelines.zip
	rm -rf bin
