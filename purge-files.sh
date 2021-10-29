#!/bin/bash

###############################################################
# Script to purge files stored in linux server directories    #
# Developer: Gabriel de Souza Nascimento                      #
# Repo: https://github.com/gasouna/purge-files                #
# Date: 2021-12-02                                            #
###############################################################

date=`date "+%Y%m%d"`
exec_date=`date "+%Y-%m-%d"`
exec_hour=`date "+%H:%M"`

serverExtIp=`hostname -i`

cd /workspace
if [[ -d Monitoramento ]]
then
   chown -R root:g_cloud_garagem01_du8_prod Monitoramento
   chmod g+s Monitoramento
   mkdir -p Monitoramento/garagem_${garagem}/OUT
   mkdir -p Monitoramento/garagem_${garagem}/LOGS
else
   mkdir Monitoramento
   chown -R root:g_cloud_garagem01_du8_prod Monitoramento
   chmod g+s Monitoramento
   mkdir -p Monitoramento/garagem_${garagem}/OUT
   mkdir -p Monitoramento/garagem_${garagem}/LOGS
fi
cd /workspace/Monitoramento/garagem_${garagem}

OUT=/workspace/Monitoramento/garagem_${garagem}/OUT
LOGS=/workspace/Monitoramento/garagem_${garagem}/LOGS
ARQ_LOG=${LOGS}/expurgo_arquivos_${garagem}_${date}.log
MONITORAMENTO=${OUT}/monitor_garagem_expurgo_${garagem}_${date}.txt

echo "[`date "+%Y-%m-%d %H:%M"`] Início da execução." >> ${ARQ_LOG}
echo "[`date "+%Y-%m-%d %H:%M"`] Definindo variáveis inicias." >> ${ARQ_LOG}

ip_interno=`hostname -I`
ip_externo=`hostname -i`
hostname=`hostname --fqdn`
cold_qtd_days_delete=`cat /etc/garagem.conf | grep cold_qtd_days_delete | cut -d"=" -f2`
expurgo=`expr $cold_qtd_days_delete - 15`

# Captura dos arquivos
echo "[`date "+%Y-%m-%d %H:%M"`] Iniciando a captura dos arquivos."
find /workspace -type f -atime +$expurgo > ${OUT}/auxiliar.out

echo "[`date "+%Y-%m-%d %H:%M"`] Foram encontrados `cat ${OUT}/auxiliar.txt | wc -l` arquivos." >> ${ARQU_LOG}
echo "[`date "+%Y-%m-%d %H:%M"`] Foram encontrados `cat ${OUT}/auxiliar.txt | grep "/.local/" | wc -l` arquivo(s) dentro de diretórios .local." >> ${ARQ_LOG}
echo "[`date "+%Y-%m-%d %H:%M"`] Foram encontrados `cat ${OUT}/auxiliar.txt | grep "/.rstudio/" | wc -l` arquivo(s) dentro de diretórios .rstudio." >> ${ARQ_LOG}
echo "[`date "+%Y-%m-%d %H:%M"`] Foram encontrados `cat ${OUT}/auxiliar.txt | grep "/.jupyter/" | wc -l` arquivo(s) dentro de diretórios .jupyter." >> ${ARQ_LOG}
echo "[`date "+%Y-%m-%d %H:%M"`] Foram encontrados `cat ${OUT}/auxiliar.txt | grep "/.ssh/" | wc -l` arquivo(s) dentro de diretórios .ssh." >> ${ARQ_LOG}
echo "[`date "+%Y-%m-%d %H:%M"`] Foram encontrados `cat ${OUT}/auxiliar.txt | grep "/.ipython/" | wc -l` arquivo(s) dentro de diretórios .ipython." >> ${ARQ_LOG}
echo "[`date "+%Y-%m-%d %H:%M"`] Foram encontrados `cat ${OUT}/auxiliar.txt | grep "/.config/" | wc -l` arquivo(s) dentro de diretórios .config." >> ${ARQ_LOG}

echo "IP_EXTERNO|IP_INTERNO|HOSTNAME|DT_EXECUCAO|HR_EXECUCAO|OWNER|CAMINHO_ARQUIVO|TAMANHO_KB|DIAS_PARA_EXPURGO" > ${MONITORAMENTO}

echo 0 > ${OUT}/aux.txt

# Remover os arquivos de configuração do expurgo e criação da lista final
cat ${OUT}/auxiliar.txt | grep -v ".local/" | grep -v ".rstudio/" | grep -v ".jupyter/" | grep -v ".ssh/" | grep -v ".ipython/" | grep -v ".config" | while read arquivo
do
   data_acesso=$(date --date=@`stat --format %X "${arquivo}"` "%Y%m%d")
   dif=`expr $(date "+%s") - $(date -d $date_acesso "+%s")`
   dif_dias=`expr $dif / 86400`

   if [[ $dif_dias -gt 90 ]]
   then
      rm -rf ${arquivo}
      echo "[`date "+%Y-%m-%d %H:%M"`] Arquivo ${arquivo} estava há ${dif_dias} dias sem acesso e foi expurgado." >> ${ARQ_LOG}
      arq_expurgados=`expr $(cat ${OUT}/aux.txt) + 1`
      echo $arq_expurgados > ${OUT}/aux.txt
   else
      echo "$ip_externo|$ip_interno|$hostname|$data_execucao|$hora_execucao|`ls -l "$arquivo" | awk {'print $3'}`|$arquivo|`ls -l "$arquivo" | awk {'print $5'}`|`expr 90 - $dif_dias`" >> ${MONITORAMENTO}
      echo "[`date "+%Y-%m-%d %H:%M"`] Arquivo ${arquivo} está a `expr 90 - $dif_dias` dias de ser expurgado." >> ${ARQ_LOG}
   fi
done

echo "Fim execucao" >> ${MONITORAMENTO}

echo "[`date "+%Y-%m-%d %H:%M"`] Resumo da execução:" >> ${ARQ_LOG}
echo "                      - Nº de arquivos na lista para expurgo: `cat ${MONITORAMENTO} | grep -v "^IP_EXTERNO|" | wc -l`" >> ${ARQ_LOG}
echo "                      - Nº de arquivos expurgados: `cat ${OUT}/aux.txt`" >> ${ARQ_LOG}
echo "" >> ${ARQ_LOG}

rm -rf ${OUT}/auxiliar.txt
rm -rf ${OUT}/aux.txt

echo "[`date "+%Y-%m-%d %H:%M"`] Fim da execução" >> ${ARQ_LOG}