#!/bin/bash

source $commonConfigurationFilePath > /dev/null
main_module="etl_edr"
module_name="etl_module"
process_name="etl_edr_p3"
sql_process_name="etl_edr_sql"
log_level="INFO" # INFO, DEBUG, ERROR
rule_engine="${APP_HOME}/rule_engine/RuleEngine-1.1.jar"

startProcess(){
oprName=$1
counter=$2

cd ${APP_HOME}/$module_name/$main_module/$process_name

echo "start for $oprName $counter  $(date "+%Y-%m-%d")"
if [ -e ${process_name}.jar ]
 then
   status=`ps -ef |  grep $main_module|  grep $process_name.jar |  grep  ${oprName}/${counter}/process/ | grep -v vi | grep java`
   if [ "$status" != "" ]
     then
       echo 0:0:OK
   else
     fileCount=`ls ${DATA_HOME}/$module_name/$main_module/${process_name}_input/${oprName}/${counter}/process/ | wc -l`

     for ((k=1; k<=$fileCount; k++))
       do
        logpath=${LOG_HOME}/$module_name/$main_module/${process_name}/${oprName}/${counter}/

        inputfilepath=${DATA_HOME}/$module_name/$main_module/${process_name}_input/${oprName}/${counter}/process/
                
          java  -Dlog_level=${log_level} -Dlog_path=${log_path} -Dmodule_name=${process_name}_${counter} -Dlog4j.configurationFile=./log4j2.xml  -Dspring.config.location=file:${commonConfigurationFilePath},file:./application.properties  -Dloader.path=${rule_engine}  -cp ${process_name}.jar org.springframework.boot.loader.PropertiesLauncher ${inputfilepath} 1>/dev/null 2>${log_path}/${module_name}.error & 
       done
     sleep 5

     status=`ps -ef  |  grep $main_module |  grep sqlFileRunner | grep -v vi | grep /${oprName}/${counter}/ `
     if [ "$status" != "$VAR" ]
        then
          echo 0:0:OK
     else
     echo "Start Sql for ${oprName}  $counter  $(date "+%Y-%m-%d")"

     fileCountSql=`ls ${DATA_HOME}/$module_name/$main_module/${sql_process_name}_input/${oprName}/${counter}/ | wc -l`
     
     for ((t=1; t<=$fileCountSql; t++))
        do
              sh  ${APP_HOME}/$module_name/$main_module/${sql_process_name}/sqlFileRunner.sh ${DATA_HOME}/$module_name/$main_module/${sql_process_name}_input/${oprName}/${counter}/ ${LOG_HOME}/$module_name/$main_module/${sql_process_name}/${oprName}/${counter}/ ${DATA_HOME}/$module_name/$main_module/${sql_process_name}_processed/${oprName}/${counter}/
          sleep 5
        done
     echo "End  Sql for ${oprName}  $counter  $(date "+%Y-%m-%d")"
     fi
   fi
else

echo "No process found"

fi
}

for i in 1 2 3 4 5 6 7 8 9 10
  do
    startProcess ${1} ${i} &
  done

echo "waiting for instances to end"
sleep 60
status_final=`ps -ef | grep $main_module  | grep -v vi | grep $1 | wc -l`
   while [ "$status_final" -gt 0 ]
     do
       echo "instances running"
       status_final=`ps -ef | grep  $main_module | grep $1 |grep -v vi | wc -l`
      sleep 60
    done
echo " Process End $i  $(date "+%Y-%m-%d")"
exit ;
