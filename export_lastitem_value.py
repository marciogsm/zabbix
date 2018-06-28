#!/usr/bin/python
# -*- coding: utf-8 -*-
################################################################################
# Descrição:
#  Autor: Fabricio Silva - Capgemini
#  Mail: fabricio.ssilva@capgemini.com
#  DATA: 2017-09-21
################################################################################
import sys, getopt
from pyzabbix import ZabbixAPI
from datetime import *
import time
import re
from re import search

# The hostname at which the Zabbix web interface is available
ZABBIX_SERVER = 'http://10.131.101.15/zabbix'
usuario = 'report_user'
senha = 'cap@123'

zapi = ZabbixAPI(ZABBIX_SERVER)

# Login to the Zabbix API
zapi.login(usuario, senha)
def mudaNomeKey(key):
    regex = search(r'(cpu)',key)
    if regex:
        key = "cpu"
        return key
    else:
        regex = search(r'(pused)',key)
        if regex:
            key = "% memoria usada"
            return key
        else:
            regex = search(r'(free)',key)
            if regex:
                key = "memoria livre"
                return key
    return key

def getItemsId(hostid,keyArr):
    if "*" not in keyArr:
        item_id = zapi.item.get(
                        filter =  {"hostid": hostid,"key_": keyArr }
                        ,output =  ['itemid','key_','value_type']
                        )
    else:
        item_id = zapi.item.get(
                        filter =  {"hostid": hostid}
                        ,search =  {"key_": keyArr }
                        ,searchWildcardsEnabled=1
                        ,output =  ['itemid','key_','value_type']
                        )

    itemsid = []
    for item in item_id:
        #itemsid.append([item['itemid'],mudaNomeKey(item['key_']),item['value_type']])
        itemsid.append([item['itemid'],item['key_'],item['value_type']])
        #print("itemid:%s, key_:%s, value_type:%s" %(item['itemid'],item['key_'],item['value_type']) )
    return itemsid

def getHistory(host,itemsid,startdate,enddate):
    date_start = startdate
    date_end =  enddate
    #date_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(1)
    #date_end =  date_start + timedelta(hours=23, minutes=59, seconds=59, microseconds=999999)
    #print('Coleta para o host %s - Inicio:%s, Fim:%s}' % (host,date_start,date_end))
    #print('Coleta para o host %s - Inicio:%s, Fim:%s}' % (host,date_start,date_end))
    #print(itemsid)
    #dados = {"host" : host}
    dados = []
    for (itemid,key,value) in itemsid:
        history = zapi.history.get(
                            history = value
                            ,time_from = time.mktime(date_start.timetuple())
                            ,time_till = time.mktime(date_end.timetuple())
                            ,itemids = itemid
                            ,output = "extend"
                            ,limit = 1
            )
        #item = {key : []}
        #print(history)
        for h in history:
            #item[key].extend([h['value']])
            #dados.update({key : h['value']})
            if(value == "0"):
                valor = h['value'].replace('.',',')+"%"
            else:
                valor = h['value']
            data=datetime.fromtimestamp(int(h['clock'])).strftime('%Y-%m-%d %H:%M:%S')
            dados.append([host,key,valor,data])
            #print(h)
        #dados.update(item)
    return dados
def getGroups(groupArr):
    groups = zapi.hostgroup.get(
            output=["name","groupid"]
            #,filter={"name":"Oracle"}
            #,filter={"name":["Servers Windows","Servers Linux","Servers Oracle"]}
            ,filter={"name":groupArr}
        )
    grouparr = []
    for group in groups:
        grouparr.append(group['groupid'])
    return grouparr

def getHostsByGroups(grouparr):
    hosts = zapi.host.get(
                groupids=grouparr
                ,output=['hostid','host']
                #,filter={"status": 0}
                #,filter={"host":"zabbix-prd"} #Linux Servers
                #,filter={"host":"CHSQL091"} #Windows Servers
            )
    return hosts

def getHostsByName(hostsarr):
    hosts = zapi.host.get(
                filter={"host": hostsarr}
                ,output=['hostid','host']
            )
    return hosts

def runReport(groups,hosts,key,startdate,enddate):
    #keyArr = ["system.cpu.util","system.cpu.util[,system]","vm.memory.size[free]","vm.memory.size[pused]"]
    #keyArr = ["system.cpu.util[,system]","system.cpu.util"]
    #keyArr = ["system.cpu.util"]
    groupArr = getGroups(groups) if (groups != '' and len(groups) > 0) else ''
    #groupArr = ["Servers Windows","Servers Linux","Servers Oracle"]
    #grouparr = getGroups(groupArr)
    hostsarr = hosts if (hosts != '' and len(hosts) > 0) else []
    hosts = getHostsByGroups(groupArr) if (groupArr != '' and len(groupArr) > 0) else getHostsByName(hostsarr)

    dadosarr = []
    print ('"host","metrica","valor","data"')
    for host in hosts:
        #print (key)
        itemsid = getItemsId(host['hostid'],key)
        #print(itemsid)
        dados = getHistory(host['host'],itemsid,startdate,enddate)
        for dado in dados:
            #valor = dado[2].replace('.',',')+"%"
            print("\"%s\",\"%s\",\"%s\",\"%s\"" % (dado[0],dado[1],dado[2],dado[3]))


def txtToDate(parametro,texto):
    if texto == '':
        if parametro in ("-s", "--startdate"):
            data =  datetime.now().replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(1)
        elif parametro in ("-e", "--enddate"):
            data = datetime.now().replace(hour=23, minute=59, second=59, microsecond=999999) - timedelta(1)
        else:
            data = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    else:
        data = datetime.strptime(texto, '%Y-%m-%d %H:%M:%S')
    return data

def main(argv):
   key = ''
   startdate = ''
   enddate = ''
   groups = ''
   hosts = ''
   try:
      opts, args = getopt.getopt(argv,"h:g:k:s:e:",["host=","group=","key=","startdate=","enddate","help"])
   except getopt.GetoptError:
      print 'report.py -h <hostname> -g <group> -k <key_name> -s <start_date> -e <end_date>'
      sys.exit(2)
   for opt, arg in opts:
      if opt == '--help':
         print 'report.py -h <hostname> -g <group> -k <key_name> -s <start_date> -e <end_date>'
         sys.exit()
      elif opt in ("-k", "--key"):
         key = arg
      elif opt in ("-s", "--startdate"):
         startdate = txtToDate(opt,arg)
      elif opt in ("-e", "--enddate"):
         enddate = txtToDate(opt,arg)
      elif opt in ("-g", "--group"):
         groups = arg.split(",")
      elif opt in ("-h", "--host"):
         hosts = arg.split(",")

   startdate = startdate if startdate != '' else txtToDate('-s','')
   enddate = enddate if enddate != '' else txtToDate('-e','')
   #print 'Key "', key
   #print 'Start date "', startdate
   #print 'End date "', enddate
   if key != '':
      runReport(groups,hosts,key,startdate,enddate)


if __name__ == "__main__":
   main(sys.argv[1:])
