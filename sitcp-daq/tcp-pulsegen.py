#!/usr/bin/env python3.9
# -*- coding: utf8 -*-

import socket
import struct
import sitcpy.rbcp as rbcp
import numpy as np
import time
import datetime

class pulse_instrument(object):
  def __init__(self,IPaddress,PortNumber=4000):
    self.s=socket.socket(socket.AF_INET,sockt.SOCK_STREAM,socket.IPPROTO_TCP)
    self.s.connect((IPaddress,PortNumber))

  def write(self):
    TBytes=0
    dt=0
    tbuff=5.0 #1e-3
    msg=b'\x77'
    for k in range(1,64):
      msg+=struct.pack('1B',k)
    for j in range(0,512):
      SBytes=self.s.send(msg)
      if SBytes==0:
        raise RuntimeError('Connection broken')
      TBytes+=SBytes
      t0=time.monotonic()
      while dt<=tbuff:
        t1=time.monotonic()
        dt=t1-t0
      dt=0
    return TBytes

  def read(self):
    TBytes=0
    Tflag=0
    dt=0
    tbuff=1e-3
    data=np.zeros(32768)
    msg=np.zeros(64)
    msg[0]=119
    for k in range(1,64):
      msg[k]=k
    for j in range(0,512):
      RBytes=self.s.recv(64)
      Mbytes=len(RBytes)
      TBytes+=Mbytes
      if Mbytes==64:
        for k in range(0,8):
          frame=RBytes[8*k],RBytes[8*k+1],RBytes[8*k+2],RBytes[8*k+3],RBytes[8*k+4],RBytes[8*k+5],RBytes[8*k+6],RBytes[8*k+7]
          data[8*k+64*j:8*(k+1)+64*j]=frame
        valid_data=data[64*j:64*(j+1)]
        Tflag+=np.any(valid_data==msg)
      t0=time.monotonic()
      while dt<=tbuff:
        t1=time.monotonic()
        dt=t1-t0
      dt=0
    return data,TBytes,Tflag

  def close(self):
    self.s.close()

def wait_time(d0,dt,t0):
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

def init_gen(dev,config):
  fconfig=open(config,'r')
  config_data=fconfig.readlines()
  fconfig.close()
  M=len(config_data)
  p=np.zeros(M)
  for j in range(0,M):
    print(j)
    cline=config_data[j].split()
    caddr=int(cline[1],16)
    cdata=struct.pack('B',int(cline[2],16))
    h=dev.write(caddr,cdata)
    time.sleep(0.2)
    if len(h)!=0:
      p[j]=1.0
  return p

ipaddr='192.168.10.16'
port_udp=4660
port_tcp=24
d0=5
dt=0
jevt=10
sync=False
p=False

date=datetime.datetime.now()

gen_config='gen_regconf.txt'
pulse_gen=rbcp.Rbcp(ipaddr,port_udp)
while p==False:
  p=init_gen(pulse_gen,gen_config)
  p=np.all(p!=0)
  time.sleep(0.5)
print('Init config done ...')

if sync==True:
  while int(time.ctime()[17:19])!=0:
    time.sleep(0.01)

pulse_gen=pulse_instrument(ipaddr,port_tcp)
print('Starting DAQ ...')
t0=time.time()
dt,t0,t2=wait_time(d0,dt,t0)

for j in range(0,jevt):
  t0=time.time()
  nbytes=pulse_gen.write()
  print(nbytes)
  t1=time.time()
  data,rbytes,tflag=pulse_gen.read()
  t2=time.time()
  dt0=t1-t0
  dt1=t2-t1
  print(rbytes,tflag)
  print(dt0,dt1)
pulse_gen.close()
