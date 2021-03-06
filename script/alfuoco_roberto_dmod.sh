#!/bin/bash

###	definizioni
HOME=/home/meteo
DIR_INI=/home/meteo/programmi/fwi_grid/ini
DIR_ANA=/home/meteo/programmi/fwi_grid/meteo/ana
DIR_PREVI=/home/meteo/programmi/fwi_grid/meteo/prev
DIR_NEVE_IMG=/home/meteo/programmi/fwi_grid/immagini/meteo/neve
DIR_IMG_PNG=/home/meteo/programmi/fwi_grid/immagini/png
DIR_ANA_IMG=/home/meteo/programmi/fwi_grid/immagini/ana
DIR_PREV_IMG=/home/meteo/programmi/fwi_grid/immagini/prev
DIR_ANAME_IMG=/home/meteo/programmi/fwi_grid/immagini/meteo/ana/archivio
DIR_PREVME_IMG=/home/meteo/programmi/fwi_grid/immagini/meteo/prev/archivio
DIR_ANAMET_IMP=/home/meteo/programmi/fwi_grid/immagini/meteo/ana
DIR_FORMET_IMP=/home/meteo/programmi/fwi_grid/immagini/meteo/prev
DIR_NONFWI_IMG=/home/meteo/programmi/non_fwi_grid/immagini/ana
SPEDIZIONI=$HOME/programmi/fwi_grid/spedizioni
DIR_VUOTI=$HOME/programmi/fwi_grid/modelli_vuoti
DIR_GRASS=/home/meteo/programmi/grass_work
# Analisi su Ghost Virtuale
WEBSERVER_V_ANA=/var/www/html/prodottimeteo/analisi/fwi
WEBSERVER_V_ANAME=/var/www/html/prodottimeteo/analisi/fwi_meteo
WEBSERVER_V_NONFWI=/var/www/html/prodottimeteo/analisi/non_fwi
# Previsione su Ghost virtuale
WEBSERVER_V_FORE=/var/www/html/prodottimeteo/forecast/fwi
WEBSERVER_V_FOREME=/var/www/html/prodottimeteo/forecast/fwi_meteo
control=$DIR_PREVI/fwi_controllo.data
datafor=$DIR_INI/data_for.ini
end_isaia=$HOME/tmp/end_isaia
end_grass=$HOME/tmp/end_grass
end_forecast=$HOME/tmp/end_forecast
underscore="_"
ll="LL"
#
SMBCLIENT=/usr/bin/smbclient
WEBESTIP=172.16.1.6
#WEBESTIP=172.16.1.2
WEBESTDIR=meteo
WEBESTDIR1=bollettini/img_aib
WEBESTDIR2=mappe/fwi_img
WEBESTDIR3=mappe/xml
#WEBESTUSR=administrator
#WEBESTPWD=siemens
WEBESTUSR=meteo_img
WEBESTPWD=meteo
WEBESTWKG=ARPA

# applicativo memorizzazione database
FWIDBMGR=$HOME/dev/redist/fwidbmgr/fwidbmgr

#count=/tmp/fwi_count
#end_grassWGS84=$HOME/tmp/end_grassWGS84.txt
#
export dataaltroieri=$(date --date='2 day ago' +"%Y%m%d") && echo $dataaltroieri
export dataieri=$(date --date=yesterday +"%Y%m%d") && echo $dataieri
export dataoggi=$(date +"%Y%m%d") && echo $dataoggi
export datadomani=$(date --date=tomorrow +"%Y%m%d") && echo $datadomani

## Inizializza immagini su web-server
if [ ! -s $end_grass.$dataoggi ]
then 
$SMBCLIENT //$WEBESTIP/$WEBESTDIR -U $WEBESTUSR%$WEBESTPWD <<End-of-smbclient0
prompt
cd $WEBESTDIR1
lcd $DIR_VUOTI
mput *ieri*
End-of-smbclient0
fi

if [ ! -s $end_forecast.$dataoggi ]
then 
$SMBCLIENT //$WEBESTIP/$WEBESTDIR -U $WEBESTUSR%$WEBESTPWD <<End-of-smbclient1
prompt
cd $WEBESTDIR1
lcd $DIR_VUOTI
mput *oggi*
mput *domani*
End-of-smbclient1
fi

###########  creazione file di neve per analisi di ieri

if [ ! -s $end_isaia.$dataoggi ] 
then

# controlla la cartella /home/meteo/programmi/fwi_grid/modis_neve
  DIR_NEVE=/home/meteo/programmi/fwi_grid/modis_neve/
  NUMFILES_NEVE=`ls -1 $DIR_NEVE* | wc -l`
  if [ "$NUMFILES_NEVE" -gt 0 ]; then
#se la directory $DIR_NEVE non e' vuota allora ...
    if [ "$NUMFILES_NEVE" -gt 1 ]
    then
  #se la directory $DIR_NEVE contiene piu' di 1 file allora ...
      echo "ERRORE: directory $DIR_NEVE contiene piu' di 1 file"
      exit 1
    else
  #...altrimenti la directory $DIR_NEVE contiene esattamente 1 file
      echo "directory $DIR_NEVE contiene 1 solo file"
    # il seguente ciclo FOR verra' ripetuto una sola volta: e' tanto per leggere il 
    #  nome dell'unico file (.img) che so essere in DIR_NEVE e ricavare la data alla quale
    # il file si riferisce (DATA_NEVE)
      for FILE in $DIR_NEVE*
      do
        echo $FILE
        DATA_NEVE=`echo $FILE | awk -F _ '{ print $NF }' | awk -F . '{ print $1 }'`
      done
      echo $DATA_NEVE
      if [ "$DATA_NEVE" == "$dataieri"  ]; then
      # se DATA_NEVE coincide con la data di IERI allora chiamo lo script per la Conversione Neve
      #  e sposto i files creati in /home/meteo/programmi/fwi_grid/meteo/ana 
             /home/meteo/script/fwi/conversione_img_neve/neve_operativo.sh
	     if [ "$?" -ne 0 ]
	     then
      	        echo "codice errore di neve_operativo"
		exit 1
	     fi 
             mv -f $DIR_NEVE/neve_$dataieri.txt $DIR_ANA/
             mv -f $DIR_NEVE/neve_$dataieri.img $DIR_ANA/
      else
      # ...altrimenti DATA_NEVE non coincide con la data di ieri
      echo "ERRORE: la directory $DIR_NEVE contiene 1 file con la data diversa da quella di ieri"
      exit 1
      fi
    fi
  else
# ...altrimenti la directory $DIR_NEVE e' vuota
      echo "directory $DIR_NEVE e' vuota"
      echo "prendo il file neve dell'altro ieri e lo copio con data di ieri"
    # prende i file neve_dataaltroieri.txt e neve_dataaltroieri.img in /home/meteo/programmi/fwi_grid/meteo/ana e li copia con la data di ieri 
      cp -f $DIR_ANA/neve_$dataaltroieri.txt $DIR_ANA/neve_$dataieri.txt
      cp -f $DIR_ANA/neve_$dataaltroieri.img $DIR_ANA/neve_$dataieri.img
  fi
fi

###	eseguo analisi, a prescindere

###	  A)  Script OI per interpolazione dati meteo + calcolo analisi FWI
if [ ! -s $end_isaia.$dataoggi ] 
then
	$HOME/script/interpolazione/oi_fwi.sh -s $dataaltroieri"1300" -e $dataieri"1200"
	if [ $? == 1 ] 
	then
		echo "codice errore di oi_fwi.sh"
		echo "vedere file di log -> /home/meteo/programmi/fwi_grid/fwigrid.log "
		exit 1
	else
		echo "ok" >$end_isaia.$dataoggi
	fi 
fi

if [ ! -s $end_grass.$dataoggi ]
then 
###     B1) GRASS meteo ANALISI
                echo "GRASS_GB_METEO inizio ========================================================================="
                /home/meteo/script/fwi/batch-grass6.sh GB PERMANENT -file $DIR_GRASS/scripts/GRASS_GB_METEO_dmod.txt
                echo "GRASS_GB_METEO fine ==========================================================================="

	for nomeindice in ffmc dmc dc isi bui fwi
	do
		export nomeindice=$nomeindice
###     B2) GRASS in GB risoluzione 1500m
#               grass63 -text $DIR_GRASS/GB/PERMANENT <  $DIR_GRASS/scripts/GRASS_GB_1500m.txt
                echo "GRASS_GB_1500m inizio ========================================================================="
                /home/meteo/script/fwi/batch-grass6.sh GB PERMANENT -file $DIR_GRASS/scripts/GRASS_GB_1500m_rgmod.txt
		if [ "$?" -ne 0 ]
		then
			echo "codice errore di grass63 in GB"
		exit 1
		fi 
                echo "GRASS_GB_1500m fine ========================================================================="

###     per utilizzo cosmo-i7
        	case $nomeindice in ffmc|dmc|dc)
###     C) GRASS in WGS84 risoluzione 7Km
#                       grass63 -text $DIR_GRASS/WGS84/PERMANENT <  $DIR_GRASS/scripts/GRASS_WGS84_7Km_I.txt
                        echo "GRASS_WGS84_7Km_I inizio ========================================================================="
                        /home/meteo/script/fwi/batch-grass6.sh WGS84 PERMANENT -file $DIR_GRASS/scripts/GRASS_WGS84_7Km_I.txt
			if [ "$?" -ne 0 ]
			then
				echo "codice errore di grass63 in WGS84"
				exit 1
			fi
                        echo "GRASS_WGS84_7Km_I fine ========================================================================="
                	;;
        	esac

                echo "ConversioneAnalisiinLatLon.txt inizio ========================================================================"
                /home/meteo/script/fwi/batch-grass6.sh WGS84 PERMANENT -file $DIR_GRASS/scripts/ConversioneAnalisiInLatLon.txt 
                echo "ConversioneAnalisiinLatLon.txt fine ========================================================================="

	done

echo "ok" >$end_grass.$dataoggi

#----------------------------------
# [10] memorizzazione db indici
#----------------------------------
echo `date +%Y-%m-%d" "%H:%M`" Memorizzazione db indici giorno: "$FWIDBDATE" FWIDBMGR_HOME="$FWIDBMGR_HOME
$FWIDBMGR -a out -d $dataieri
echo `date +%Y-%m-%d" "%H:%M`" DONE."

#----------------------------------
# [11] calcolo nuovi indici
#----------------------------------
echo `date +%Y-%m-%d" "%H:%M`" Calcolo nuovi indici giorno: "$FWIDBDATE" FWIDBMGR_HOME="$FWIDBMGR_HOME
$FWIDBMGR -a computeidx -d $dataieri
echo `date +%Y-%m-%d" "%H:%M`" DONE."

#----------------------------------
# [12] export nuovi indici
#----------------------------------
echo `date +%Y-%m-%d" "%H:%M`" Export nuovi indici giorno: "$FWIDBDATE" FWIDBMGR_HOME="$FWIDBMGR_HOME
$FWIDBMGR -a exportidx -d $dataieri
echo `date +%Y-%m-%d" "%H:%M`" DONE."

###     GRASS FMI ANALISI
                echo "GRASS_GB_METEO inizio ========================================================================="
                /home/meteo/script/fwi/batch-grass6.sh GB PERMANENT -file $DIR_GRASS/scripts/GRASS_GB_FMI.txt
                echo "GRASS_GB_METEO fine ==========================================================================="

###	conversione file in formato gif ANALISI -> creazione impaginata

convert \( $DIR_NEVE_IMG/neve_$dataieri.gif $DIR_ANA_IMG/IDI_comune_$dataieri.gif +append \) \
        \( $DIR_ANA_IMG/ffmc_legenda_$dataieri.gif $DIR_ANA_IMG/ffmc_mask_$dataieri.gif +append \) \
        \( $DIR_ANA_IMG/dmc_legenda_$dataieri.gif $DIR_ANA_IMG/dmc_mask_$dataieri.gif +append \) \
        \( $DIR_ANA_IMG/dc_legenda_$dataieri.gif $DIR_ANA_IMG/dc_mask_$dataieri.gif +append \) \
        \( $DIR_ANA_IMG/isi_legenda_$dataieri.gif $DIR_ANA_IMG/isi_mask_$dataieri.gif +append \) \
        \( $DIR_ANA_IMG/bui_legenda_$dataieri.gif $DIR_ANA_IMG/bui_mask_$dataieri.gif +append \) \
        \( $DIR_ANA_IMG/fwi_legenda_$dataieri.gif $DIR_ANA_IMG/fwi_mask_$dataieri.gif +append \) \
        \( -size 100x200 xc:none +append \) \
        -background none -append $DIR_ANA_IMG/impaginata_$dataieri.gif

###     Impaginata meteo ANALISI

convert \( $DIR_ANAME_IMG/t_$dataieri.gif $DIR_ANAME_IMG/ur_$dataieri.gif +append \) \
	\( $DIR_ANAME_IMG/ws_$dataieri.gif $DIR_ANAME_IMG/prec24_$dataieri.gif +append \) \
	\( -size 100x200 xc:none +append \) \
	-background none -append $DIR_ANAMET_IMP/impaginatameteo_$dataieri.gif
convert $DIR_ANAMET_IMP/impaginatameteo_$dataieri.gif -crop 1600x1200 +repage $DIR_ANAMET_IMP/impaginatameteo_$dataieri.gif

###	Impaginata NONFWI ANALISI

convert \( $DIR_NONFWI_IMG/archivio/angstrom_legenda_$dataieri.gif $DIR_NONFWI_IMG/archivio/angstrom_mask_$dataieri.gif +append \) \
        \( $DIR_NONFWI_IMG/archivio/fmi_legenda_$dataieri.gif $DIR_NONFWI_IMG/archivio/fmi_mask_$dataieri.gif +append \) \
        \( $DIR_NONFWI_IMG/archivio/sharples_legenda_$dataieri.gif $DIR_NONFWI_IMG/archivio/sharples_mask_$dataieri.gif +append \) \
        \( -size 100x200 xc:none +append \) \
        -background none -append $DIR_NONFWI_IMG/impaginata_NONFWI_$dataieri.gif

###	copio ANALISI impaginata su Ghost Virtuale
scp $DIR_ANA_IMG/impaginata_$dataieri.gif meteo@10.10.0.14:$WEBSERVER_V_ANA
scp $DIR_ANAMET_IMP/impaginatameteo_$dataieri.gif meteo@10.10.0.14:$WEBSERVER_V_ANAME/
scp $DIR_NONFWI_IMG/impaginata_NONFWI_$dataieri.gif meteo@10.10.0.14:$WEBSERVER_V_NONFWI/

# copio analisi su WEB-SERVER ARPA 172.16.1.6/ecc
# A) copia delle mappe con aggregazione su Aree 
rm -f $SPEDIZIONI/*
cp $DIR_ANA_IMG/*_legenda_$dataieri.gif $SPEDIZIONI/
rename legenda_$dataieri ieri $SPEDIZIONI/*.gif
$SMBCLIENT //$WEBESTIP/$WEBESTDIR -U $WEBESTUSR%$WEBESTPWD <<End-of-smbclient2
prompt
cd $WEBESTDIR1
lcd $SPEDIZIONI
mput *
End-of-smbclient2
#
# B) copia delle mappe originali mascherate con neve\idi\aree non bruciabili per GoogleMaps (e in piÃ¹ mappe aggregate per thumbnails)
rm $SPEDIZIONI/*.*
cp $DIR_ANA_IMG/*_mask_$dataieri.png $SPEDIZIONI/
cp $DIR_ANA_IMG/*_AO_$dataieri.png $SPEDIZIONI/
cp $DIR_ANA_IMG/*_$dataieri$underscore$ll.png $SPEDIZIONI/
cp $DIR_ANA_IMG/*_AO_$dataieri$underscore$ll.png $SPEDIZIONI/
rename $dataieri$underscore$ll ieri $SPEDIZIONI/*.png
rename AO_$dataieri$underscore$ll A0_ieri $SPEDIZIONI/*.png
$SMBCLIENT //$WEBESTIP/$WEBESTDIR -U $WEBESTUSR%$WEBESTPWD <<End-of-smbclient3
prompt
cd $WEBESTDIR2
lcd $SPEDIZIONI
mput *
End-of-smbclient3

fi

#----------------------------------
# [13] memorizzazione db immagini
#----------------------------------
echo `date +%Y-%m-%d" "%H:%M`" Memorizzazione db immagini giorno: "$FWIDBDATE
$FWIDBMGR -a outimg -d $dataieri
echo `date +%Y-%m-%d" "%H:%M`" DONE."

###	fine esecuzione analisi

###	eseguo forecast, triggerato da file control
datacontrologgi=`cat $control|cut -d' ' -f1` && echo $datacontrol
datacontrolieri=$(date +%Y%m%d --date "$dataoggi -24 hour") && echo $datacontrolieri
datacontroldomani=$(date +%Y%m%d --date "$dataoggi +24 hour") && echo $datacontroldomani

### controllo se la parte di forecast oggi e' gia' stata eseguita
if [ -s $end_forecast.$dataoggi ]
then 
      echo "Forecast gia' eseguita precedentemente. Esco"
      exit 0
fi

###	controllo se esiste file control di oggi
if [ ! -s $control ]
then
	echo "non esiste ancora file $control in data $(date)"
	exit
else
      if [ "$datacontrologgi" == "$dataoggi" ]
      then
###	D) FORTRAN PREVISIONE
            echo $dataieri"  "$dataoggi"  "$datadomani > $datafor
            /home/meteo/programmi/fwi_grid/fwigrid_for_1.4

	    if [ "$?" -ne 0 ]
	    then
	        echo "codice errore di fwigrid_for"
	        exit 1
	    fi 

	    for nomeindice in ffmc dmc dc isi bui fwi
	    do
                export nomeindice=$nomeindice
###	E) GRASS in WGS84 risoluzione 7Km
#	        grass63 -text $DIR_GRASS/WGS84/PERMANENT < $DIR_GRASS/scripts/GRASS_WGS84_7Km_II.txt
                echo "GRASS_WGS84_7Km_II inizio ========================================================================="
                /home/meteo/script/fwi/batch-grass6.sh WGS84 PERMANENT -file $DIR_GRASS/scripts/GRASS_WGS84_7Km_II.txt 
                echo "GRASS_WGS84_7Km_II fine ========================================================================="
                echo "ConversionePrevisioneInGB.txt inizio ========================================================================"
                /home/meteo/script/fwi/batch-grass6.sh GB PERMANENT -file $DIR_GRASS/scripts/ConversionePrevisioneInGB_dmod.txt 
                echo "ConversionePrevisioneInGB.txt  fine ========================================================================="
	    done

                echo "GRASS_WGS84_METEO_I inizio ========================================================================="
                /home/meteo/script/fwi/batch-grass6.sh WGS84 PERMANENT -file $DIR_GRASS/scripts/GRASS_WGS84_METEO_I_dmod.txt 
                echo "GRASS_WGS84_METEO_I fine ==========================================================================="
                echo "GRASS_WGS84_METEO_II inizio ========================================================================"
                /home/meteo/script/fwi/batch-grass6.sh GB PERMANENT -file $DIR_GRASS/scripts/GRASS_WGS84_METEO_II_dmod.txt 
                echo "GRASS_WGS84_METEO_II  fine ========================================================================="

###	F) CREO file per compilazione "Vigilanza AIB"	
            /home/meteo/programmi/fwi_grid/creaxvigaib_2.1
	    if [ "$?" -ne 0 ]
	    then
		echo "codice errore di creaxvigaib"
	    exit 1
	    fi 


###	conversione file in formato gif FORECAST -> creazione impaginata

            numero=1

    convert \( $DIR_PREV_IMG/ffmc_AO_$dataoggi$underscore$numero.gif $DIR_PREV_IMG/ffmc_$dataoggi$underscore$numero.gif +append \) \
            \( $DIR_PREV_IMG/dmc_AO_$dataoggi$underscore$numero.gif $DIR_PREV_IMG/dmc_$dataoggi$underscore$numero.gif +append \) \
            \( $DIR_PREV_IMG/dc_AO_$dataoggi$underscore$numero.gif $DIR_PREV_IMG/dc_$dataoggi$underscore$numero.gif +append \) \
            \( $DIR_PREV_IMG/isi_AO_$dataoggi$underscore$numero.gif $DIR_PREV_IMG/isi_$dataoggi$underscore$numero.gif +append \) \
            \( $DIR_PREV_IMG/bui_AO_$dataoggi$underscore$numero.gif $DIR_PREV_IMG/bui_$dataoggi$underscore$numero.gif +append \) \
            \( $DIR_PREV_IMG/fwi_AO_$dataoggi$underscore$numero.gif $DIR_PREV_IMG/fwi_$dataoggi$underscore$numero.gif +append \) \
            \( -size 100x200 xc:none +append \) \
            -background none -append $DIR_PREV_IMG/impaginata_$dataoggi$underscore"1".gif

###     impagino mappe meteo oggi in previsione
    convert \( $DIR_PREVME_IMG/t_lami_$dataoggi$underscore$numero.gif $DIR_PREVME_IMG/ur_lami_$dataoggi$underscore$numero.gif +append \) \
	    \( $DIR_PREVME_IMG/ws_lami_$dataoggi$underscore$numero.gif $DIR_PREVME_IMG/prec24_lami_$dataoggi$underscore$numero.gif +append \) \
	    \( -size 100x200 xc:none +append \) \
	    -background none -append $DIR_FORMET_IMP/impaginatameteo_$dataoggi$underscore"1".gif
    convert $DIR_FORMET_IMP/impaginatameteo_$dataoggi$underscore"1".gif -crop 1600x1200 +repage $DIR_FORMET_IMP/impaginatameteo_$dataoggi$underscore"1".gif

            numero=2
    convert \( $DIR_PREV_IMG/ffmc_AO_$datadomani$underscore$numero.gif $DIR_PREV_IMG/ffmc_$datadomani$underscore$numero.gif +append \) \
            \( $DIR_PREV_IMG/dmc_AO_$datadomani$underscore$numero.gif $DIR_PREV_IMG/dmc_$datadomani$underscore$numero.gif +append \) \
            \( $DIR_PREV_IMG/dc_AO_$datadomani$underscore$numero.gif $DIR_PREV_IMG/dc_$datadomani$underscore$numero.gif +append \) \
            \( $DIR_PREV_IMG/isi_AO_$datadomani$underscore$numero.gif $DIR_PREV_IMG/isi_$datadomani$underscore$numero.gif +append \) \
            \( $DIR_PREV_IMG/bui_AO_$datadomani$underscore$numero.gif $DIR_PREV_IMG/bui_$datadomani$underscore$numero.gif +append \) \
            \( $DIR_PREV_IMG/fwi_AO_$datadomani$underscore$numero.gif $DIR_PREV_IMG/fwi_$datadomani$underscore$numero.gif +append \) \
            \( -size 100x200 xc:none +append \) \
            -background none -append $DIR_PREV_IMG/impaginata_$datadomani$underscore"0".gif

###     impagino mappe meteo oggi in previsione
    convert \( $DIR_PREVME_IMG/t_lami_$dataoggi$underscore$numero.gif $DIR_PREVME_IMG/ur_lami_$dataoggi$underscore$numero.gif +append \) \
	    \( $DIR_PREVME_IMG/ws_lami_$dataoggi$underscore$numero.gif $DIR_PREVME_IMG/prec24_lami_$dataoggi$underscore$numero.gif +append \) \
	    \( -size 100x200 xc:none +append \) \
	    -background none -append $DIR_FORMET_IMP/impaginatameteo_$datadomani$underscore"0".gif
    convert $DIR_FORMET_IMP/impaginatameteo_$datadomani$underscore"0".gif -crop 1600x1200 +repage $DIR_FORMET_IMP/impaginatameteo_$datadomani$underscore"0".gif

  
###	copio FORECAST impaginata su ghost 2

            rm -fv $WEBSERVER_V_FORE/*.gif
            scp $DIR_PREV_IMG/impaginata_$dataoggi$underscore"1".gif meteo@10.10.0.14:$WEBSERVER_V_FORE/
            scp $DIR_PREV_IMG/impaginata_$datadomani$underscore"0".gif meteo@10.10.0.14:$WEBSERVER_V_FORE/
            rm -fv $WEBSERVER_V_FOREME/*.gif
            scp $DIR_FORMET_IMP/impaginatameteo_$dataoggi$underscore"1".gif meteo@10.10.0.14:$WEBSERVER_V_FOREME/
            scp $DIR_FORMET_IMP/impaginatameteo_$datadomani$underscore"0".gif meteo@10.10.0.14:$WEBSERVER_V_FOREME/

# copio FORECAST su WEB SERVER ARPA 172.16.1.6/ecc
# A) copia delle mappe con aggregazione su Aree
            rm $SPEDIZIONI/*
            cp $DIR_PREV_IMG/*AO*$dataoggi$underscore"1".gif $SPEDIZIONI/
            cp $DIR_PREV_IMG/*AO*$datadomani$underscore"2".gif $SPEDIZIONI/
            rename AO_$dataoggi$underscore"1" oggi $SPEDIZIONI/*.gif
            rename AO_$datadomani$underscore"2" domani $SPEDIZIONI/*.gif
$SMBCLIENT //$WEBESTIP/$WEBESTDIR -U $WEBESTUSR%$WEBESTPWD <<End-of-smbclient4
prompt
cd $WEBESTDIR1
lcd $SPEDIZIONI
mput *
End-of-smbclient4

# B) copia delle mappe originali mascherate con neve\idi\aree non bruciabili per GoogleMaps (e in piÃ¹ mappe aggregate per thumbnails)
            rm $SPEDIZIONI/*
            cp $DIR_PREV_IMG/*_$dataoggi$underscore"1".png $SPEDIZIONI/
            cp $DIR_PREV_IMG/*_$datadomani$underscore"2".png $SPEDIZIONI/
            rename $underscore$dataoggi$underscore"1" _oggi $SPEDIZIONI/*.png
            rename $underscore$datadomani$underscore"2" _domani $SPEDIZIONI/*.png
$SMBCLIENT //$WEBESTIP/$WEBESTDIR -U $WEBESTUSR%$WEBESTPWD <<End-of-smbclient5
prompt
cd $WEBESTDIR2
lcd $SPEDIZIONI
mput *
End-of-smbclient5
#
# Copia su /previsore del file per la compilazione del bollettino "Vigilanza AIB"
            rm $SPEDIZIONI/*.*
            cp $DIR_INI/creaxvigaib$underscore$dataieri".txt" $SPEDIZIONI/
            cp $DIR_INI/creaxvigaib$underscore$dataoggi".txt" $SPEDIZIONI/ 
            cp $DIR_INI/creaxvigaib$underscore$datadomani".txt" $SPEDIZIONI/
            cp $DIR_INI/creaxvigalp$underscore$dataieri".txt" $SPEDIZIONI/
            cp $DIR_INI/creaxvigalp$underscore$dataoggi".txt" $SPEDIZIONI/
            cp $DIR_INI/creaxvigalp$underscore$datadomani".txt" $SPEDIZIONI/
            WEBPREVIP=10.10.0.10
            WEBPREVDIR=F
            WEBPREVDIR1=Incendi_boschivi/creaxvigaib/
			WEBPREVDIR2="\Precompilazione\AIB_vig"
            WEBPREVUSR=ARPA/meteo
            WEBPREVPWD="%meteo2010"
# ...prima perÃ² li copio su meteo.arpalombardia.it/Precompilazione/AIB/bolvig
scp $SPEDIZIONI/creaxvigaib* meteoweb@172.16.1.10:/var/www/meteo/Precompilazione/AIB/bolvig			

$SMBCLIENT //$WEBPREVIP/$WEBPREVDIR -U $WEBPREVUSR%$WEBPREVPWD <<End-of-smbclient6
prompt
cd $WEBPREVDIR1
lcd $SPEDIZIONI
mput creaxvigaib*
cd $WEBPREVDIR2
mput creaxvigaib*
End-of-smbclient6
#

# Copia su /previsore delle mappe per la compilazione del bollettino "Meteo Stagione AIB"
            rm $SPEDIZIONI/*.*
            cp $DIR_ANA_IMG/ffmc$underscore"mask"$underscore$dataieri".gif" $SPEDIZIONI/
            cp $DIR_ANA_IMG/dmc$underscore"mask"$underscore$dataieri".gif" $SPEDIZIONI/
	    cp $DIR_ANA_IMG/dc$underscore"mask"$underscore$dataieri".gif" $SPEDIZIONI/
	    cp $DIR_NEVE_IMG/neve$underscore$dataieri".gif" $SPEDIZIONI/
            WEBPREVDIR2=Incendi_boschivi/Meteo_stagione/mappe/ffmc/
            WEBPREVDIR3=../dmc/
            WEBPREVDIR4=../dc/
            WEBPREVDIR5=../neve/
$SMBCLIENT //$WEBPREVIP/$WEBPREVDIR -U $WEBPREVUSR%$WEBPREVPWD <<End-of-smbclient7
prompt
cd $WEBPREVDIR2
lcd $SPEDIZIONI
mput ffmc*
cd $WEBPREVDIR3
mput dmc*
cd $WEBPREVDIR4
mput dc*
cd $WEBPREVDIR5
mput neve*
End-of-smbclient7
#

#       script per ftp alpffirs 

           /home/meteo/programmi/fwi_grid/xml/createXML_prova.sh > /home/meteo/tmp/arcibaldone.log 2>&1


            echo "ok" >$end_forecast.$dataoggi
#           fine FORECAST

      else	
	    echo "$datacontrologgi non e' uguale a $dataoggi: problemi corsa cosmoi7"
	    exit 1
      fi
fi

echo "<font face="Verdana, Arial, Helvetica, sans-serif"><font size=4><b>`date +%d-%m-%Y`</b></font>" > $HOME/programmi/fwi_grid/dataoggi.html
$SMBCLIENT //$WEBESTIP/$WEBESTDIR -U $WEBESTUSR%$WEBESTPWD <<End-of-smbclient7
prompt
cd $WEBESTDIR3
lcd $HOME/programmi/fwi_grid 
put dataoggi.html 
End-of-smbclient7
 
exit 0
