#!/bin/bash

# Made in Nikita Nuzhdenko
#
# This script parses nginx logs and takes required info
# exit 0 - successfull end of the script;
# error codes:
# 1 - script already running;
# 2 - not all required paremeters specified;
# 3 - file empty or invalid;
# 3 - empty file name;
# check if script already running

set -eo pipefail
main_function(){
  local temp=/tmp/log_analyser_dates.tmp
  local current_data=$(date "+%d/%b/%Y:%T")
  local current_data_sec=$(date +%s)
  local my_str="ЗАПИСИ ОБРАБОТАНЫ "$current_data

  # Выводим текущую дату
  echo "Текущая дата: $current_data"

  # Проверяем, запускался ли скрипт до этого момента. Если да, то получаем дату последнего запуска
  if [ -f $temp ]; then
    local last_data_sec=$(cat $temp | tail -n 1)
    local last_data=$(date --date=@$last_data_sec "+%d/%b/%Y:%T")
    echo "Прошлая дата анализа: $last_data"
  fi

  # Считаем количество новых записей в логе
  echo "Начат подсчет новых записей"
  local new_records_count=$( tac $1 | awk '{  if ( $1=="ЗАПИСИ" && $2=="ОБРАБОТАНЫ" ) exit 0 ; else print }' | wc -l || true )

  if [ $new_records_count -le 0 ]; then
    echo "Нет новых записей в $1 с $last_data"
    echo $current_data_sec >> $temp
    exit 0
  fi

  echo "Количество новых записей в log-файле: $new_records_count"
  echo $my_str >> $1

  local start_time_rande=$(cat $1 | head --line -1 | cut -d ' ' -f 4 | tail -n $new_records_count | sort -n | head -n1 | awk -F"[" '{print $2}' || true)
  local finish_time_rande=$(cat $1 | head --line -1 | cut -d ' ' -f 4 | tail -n $new_records_count | sort -nr | head -n1 | awk -F"[" '{print $2}' || true)
  echo -e "Обрабатываемый диапазон: $start_time_rande - $finish_time_rande"

  echo -e "\nТоп-15 IP-адресов, с которых посещался сайт\n"
  cat $1 |
  head --line -1 |
  tail -n $new_records_count |
  cut -d ' ' -f 1 |
  sort |
  uniq -c |
  sort -nr |
  head -n 15 |
  awk '{ t = $1; $1 = $2; $2 = t; print $1,"\t\t",$2; }' || true

  echo -e "\nТоп-15 ресурсов сайта, которые запрашивались клиентами\n"
  cat $1 |
  head --line -1 |
  tail -n $new_records_count |
  cut -d ' ' -f 7 |
  sort |
  uniq -c |
  sort -nr |
  head -n 15 |
  awk '{ t = $1; $1 = $2; $2 = t; print $1,"\t",$2; }' || true

  echo -e "\nСписок всех кодов возврата\n"
  cat $1 |
  head --line -1 |
  tail -n $new_records_count |
  cut -d ' ' -f 9 |
  sort |
  sed 's/[^0-9]*//g' |
  awk -F '=' '$1 > 100 {print $1}' |
  uniq -c  |
  head -n 15 |
  awk '{ t = $1; $1 = $2; $2 = t; print $1,"\t\t\t",$2; }'|| true

  echo -e "\nСписок кодов возврата 4xx и 5xx (только ошибки)\n"
  cat $1 |
  head --line -1 |
  tail -n $new_records_count |
  cut -d ' ' -f 9 |
  sort |
  sed 's/[^0-9]*//g' |
  awk -F '=' '$1 > 400 {print $1}' |
  uniq -c  |
  head -n 15 |
  awk '{ t = $1; $1 = $2; $2 = t; print $1,"\t\t\t",$2; }'|| true

  # Записываем дату последнего запуска скрипта
  echo $current_data_sec >> $temp
}


request=$(ps aux | grep $0 | wc -l)
if [[ $request -gt 3 ]]        #  gt - больше      проверка на мультизапуск  (3 - эмпирически выведенное значение)
then
  #если больше 3 - значит запущена еще одна команда
  echo "Запущена еще одна копия данного скрипта - я завершаю работу."
  exit 40
else  #проверка пройдена - запущена всего одна копия данного скрипта, значит, продолжаем работу

  if [[ $1 != "" ]]; then
    #код, который выполняется, ежели у нас есть первый параметр
    if [[ -f $1 ]]  # Есть файл или нет
    then
      # echo "Файлик существует. Ты молодец"
      if [[ -s $1 ]]      # проверка на пустоту файла
      then
        main_function $1
      else
        exit 30
      fi
    else
      # echo "Ты меня обманул: это не файлик!"
      exit 20
    fi
  else
    # echo "Параметр не был передан - лежим в слезах с ошибкой 10"
    exit 10
  fi

fi
exit 0
