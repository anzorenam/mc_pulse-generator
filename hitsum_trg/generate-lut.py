#!/usr/bin/env python3.9
# -*- coding: utf8 -*-

import numpy as np

hexfile='hitsum_trg.hex'
coefile='hitsum_trg.coe'
f0=open(hexfile,'w')
f1=open(coefile,'w')
head_coe0='memory_initialization_radix=10;'
head_coe1='memory_initialization_vector='
endf=':00000001FF'

N=16
M=2**16
s=np.arange(M,dtype=np.uint16)
byte=np.zeros(M,dtype=np.uint8)

for k in range(0,4096):
  shead=((N*k)&0x00FF)+(((N*k)>>8)&0x00FF)
  reg=':10{0:04X}00'.format(N*k)
  cheks=np.uint32(shead+N)
  for j in range(0,N):
    byte[N*k+j]=bin(s[N*k+j]).count('1')
    if byte[N*k+j]==16:
      byte[N*k+j]=15
    reg+='{0:02X}'.format(byte[N*k+j])
    cheks+=np.uint32(byte[N*k+j])
  cheks=np.uint32(cheks^0xFFFF)+np.uint32(1)
  reg+='{0:02X}'.format(cheks&0x00FF)
  f0.write(reg+'\n')
f0.write(endf)
f0.close()

f1.write(head_coe0+'\n')
f1.write(head_coe1+'\n')
for k in range(0,M):
  line='{0:d}'.format(byte[k])
  if k==65535:
    endl=';'
  else:
    endl=',\n'
  reg=line+endl
  f1.write(reg)
f1.close()
