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
