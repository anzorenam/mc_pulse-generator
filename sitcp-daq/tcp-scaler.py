#!/usr/bin/env python3.9
# -*- coding: utf8 -*-

import socket
import sitcpy.rbcp as rbcp
import numpy as np
import time
import datetime

class scaler_instrument(object):
  def __init__(self,IPaddress,PortNumber=4000):
    self.s=socket.socket(socket.AF_INET,socket.SOCK_STREAM,socket.IPPROTO_TCP)
    self.s.connect((IPaddress,PortNumber))

  def read(self):
    byte=self.s.recv(4)
    M=len(byte)
    if M==4:
      data0=(byte[0]<<8)+byte[1]
      data1=(byte[2]<<8)+byte[3]
    else:
      data0,data1=0,0
    return data0,data1

  def close(self):
    self.s.close()

def wait_daq(d0,dt,t0):
  daqtime=d0
  daqtime+=dt
  t1=t0
  t2=time.time()
  while (t2-t1)<daqtime:
    time.sleep(0.01)
    t2=time.time()
  t0=t2
  dt=int(time.ctime(t2)[17:19])-int(time.ctime(t1)[17:19])-daqtime
  if dt==-60:
    dt=0
  elif dt==-59:
    dt=1
  elif dt==-61:
    dt=-1
  return dt,t0,t2

def init_daq(dev,addr0,addr1):
  try:
    dev.write(addr0,b'\x07')
    dev.write(addr1,b'\x14')
    p=True
  except:
    p=False
  return p

ipaddr='192.168.10.16'
port_udp=4660
port_tcp=24
d0=20
dt=0
jevt=180
sync=True
p=False

date=datetime.datetime.now()
name='TS{0}.dat'.format(date.strftime('%y%m%d_%H%M'))
f=open(name,'w')

waddr0,waddr1,=0x08,0x09,
waddr2,waddr3=0x0A,0x0B
scaler=rbcp.Rbcp(ipaddr,port_udp)

scaler=rbcp.Rbcp(ipaddr,port_udp)
while p==False:
  p=init_daq(scaler,waddr0,waddr1)
  time.sleep(0.2)
print('Init config done ...')

if sync==True:
  while int(time.ctime()[17:19])!=0:
    time.sleep(0.01)

scaler=scaler_instrument(ipaddr,port_tcp)
print('Starting DAQ ...')
for j in range(0,jevt):
  t0=time.time()
  dt,t0,t2=wait_daq(d0,dt,t0)
  counts0,counts1=scaler.read()
  tiempo=time.gmtime(t2)
  hora_pant=time.strftime('%y%m%d %H:%M:%S',tiempo)
  data='{0} {1} {2}'.format(hora_pant,counts0,counts1)
  f.write(data)
  f.write('\n')
scaler.close()
print('DAQ finished...')
f.close()
