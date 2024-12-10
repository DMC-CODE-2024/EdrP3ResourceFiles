#!/bin/bash

#set -x

module_name="etl_edr_p3"
main_module="etl_edr" #keep it empty "" if there is no main module 
log_level="INFO" # INFO, DEBUG, ERROR

########### DO NOT CHANGE ANY CODE OR TEXT AFTER THIS LINE #########

op_name=$1

build_path="${APP_HOME}/${main_module}_module/${module_name}"
build="${module_name}.jar"

cd ${build_path}

### Start Sub-Procedure ###

start_java_process()
{
  op_name=$1
  counter=$2

  #input_path="${DATA_HOME}/${main_module}_module/${module_name}/input/${op_name}/${counter}"  
  log_path="${LOG_HOME}/${main_module}_module/${module_name}/${op_name}/${counter}"

  status=`ps -ef | grep java | grep "$build ${op_name} ${counter}" | grep -v grep`

  if [ "${status}" != "" ]  ## Process is currently running
  then
    echo "$(date) ${module_name} [${op_name}]-[${counter}]: ${module_name} ${op_name} ${counter} is currently running... skip to start java process..."

  else  ## No process running

    echo "$(date) ${module_name} [${op_name}]: start P3 java process for ${op_name} [${counter}]... "

    mkdir $log_path -p

    cd ${build_path}

    java -Dlog.path=${log_path} -Dlog.level=${log_level} -Dmodule.name=${module_name}_${counter}  -Dlog4j.configurationFile=./log4j2.xml  -Dspring.config.location=file:./application.properties,file:${commonConfigurationFile} -jar ${build} ${op_name} ${counter} 1>/dev/null 2>${log_path}/${module_name}_${counter}.error  

    echo "$(date) ${module_name} [${op_name}]: P3 java process for ${op_name} [${counter}] is completed !!! "
    echo "$(date) ${module_name} [${op_name}]: ==> calling next sql process for ${op_name} [${counter}]... "
    
    cd "${APP_HOME}/${main_module}_module/${main_module}_sql"

    ./${main_module}_sql.sh ${op_name} ${counter} 

    echo "$(date) ${main_module}_sql [${op_name}]: sql process for ${op_name} [${counter}] is completed !!! "     

  fi
 
}

### END Sub-Procedure ###
	

echo "$(date) ${module_name} [${op_name}]: ==> starting P3 process ..."

for i in 1 2 3 4 5 6 7 8 9 10
do
  start_java_process ${op_name} ${i} &
  sleep 3 
done

echo "$(date) ${module_name} [${op_name}]: waiting P3 java process & sql process for all ${op_name} instances to be completed... "


status_final=`ps -ef | grep java | grep "$build ${op_name} ${counter}" | grep -v grep | wc -l`

while [ "$status_final" -gt 0 ]
do
  sleep 15
  status_final=`ps -ef | grep $build | grep java | grep ${op_name} | grep -v grep | wc -l`
done

wait $!

echo "$(date) ${module_name} [${op_name}]: ==> P3 process is completed !!! "
echo "$(date) ${main_module}_sql [${op_name}]: ==> sql process is completed !!! "

