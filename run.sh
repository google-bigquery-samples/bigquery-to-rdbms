#!/bin/bash
# run.sh
# @See https://cloud.google.com/bigquery/bq-command-line-tool
# @See https://cloud.google.com/bigquery/docs/exporting-data
# @See https://github.com/embulk/embulk

dstPrj=dwprj7
dstSet=dc1
dstTbl=orders_summary
today=$1
yyyymm=$(date -d$today +%Y%m)
extCode=$?

#0 check if duplicate execution
if [ $extCode -eq 0 ]
then
  sql=${dstTbl}_$today.sql
  if [ -f log/$yyyymm/$sql ]
  then
    extCode=2
    echo "$sql: done already!"
  elif [ -f $sql ]
  then
    extCode=1
    echo "$sql: IN PROGRESS!"
  else
    extCode=0
  fi
fi

#1 summarize orders on BigQuery
if [ $extCode -ne 0 ]
then
  exit
else
  sql=${dstTbl}_$today.sql
  cp $dstTbl.sql.template $sql
  sed -i s/__today__/$today/g $sql
  cat $sql
  cat $sql | bq query \
    --destination_table $dstPrj:$dstSet.${dstTbl}_$today \
    --nouse_cache \
    --replace
  extCode=$?
fi

#2 export summary to GCS as CSV
if [ $extCode -eq 0 ]
then
  bq extract \
    $dstPrj:$dstSet.${dstTbl}_$today \
    gs://$dstPrj/$yyyymm/${dstTbl}_$today.csv
  extCode=$?
fi

#3 load CSV to MySQL
if [ $extCode -eq 0 ]
then
  yml=${dstTbl}_$today.yml.liquid
  cp $dstTbl.yml.template $yml
  sed -i s/__today__/$today/g $yml
  sed -i s/__yyyymm__/$yyyymm/g $yml
  cat $yml
  $EMBULK_HOME/bin/embulk \
    run $yml
  extCode=$?
fi

#0 mark success, or clean failure
if [ $extCode -eq 0 ]
then
  mv $sql log/$yyyymm/$sql
  mv $yml log/$yyyymm/$yml
else
  rm $sql
  rm $yml
fi
  
