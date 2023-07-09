#! /usr/bin/python
from TOSSIM import *
import sys

t = Tossim([])
r = t.radio()
f = open("topo6.txt", "r")

for line in f:
	s = line.split()
	if s:
		print " ", s[0], " ", s[1], " ", s[2];
		r.add(int(s[0]), int(s[1]), float(s[2]))

t.addChannel("RadioCountToLedsC", sys.stdout)
t.addChannel("Boot", sys.stdout)

noise = open("meyer-heavy.txt", "r")
for line in noise:
	str1 = line.strip()
	if str1:
		val = int(str1)
		for i in range(1, 7):
			t.getNode(i).addNoiseTraceReading(val)

for i in range(1, 7):
	print "Creating noise model for ",i;
	t.getNode(i).createNoiseModel()

t.getNode(1).bootAtTime(100001);
t.getNode(2).bootAtTime(200001);
t.getNode(3).bootAtTime(300001);
t.getNode(4).bootAtTime(400001);
t.getNode(5).bootAtTime(500001);
t.getNode(6).bootAtTime(600001);

for i in range(10000):
	t.runNextEvent()

Send = [0] * 6
Send_Succ = [0] * 6
Delay_Sum = [0] * 6

def cut_line(line):
    line_list = line.split(' ')
    if (len(line_list) < 3):
        return
    send_time_list = line_list[2].split(':')
    send_hour = int(send_time_list[0])
    send_min = int(send_time_list[1])
    send_sec = int(send_time_list[2])

    type = line_list[0]
    send_node = int(line_list[1])
    if (send_node == 0):
        return
    if (type == 'Send'):
        Send[send_node - 1] += 5
    else:
        recv_node = int(line_list[3])
        Send_Succ[send_node - 1] += 1
        recv_time_list = line_list[4].split(':')
        recv_hour = int(recv_time_list[0])
        recv_min = int(recv_time_list[1])
        recv_sec = int(recv_time_list[2])

        delay = (recv_hour - send_hour) * 3600 + (recv_min - send_min) * 60 + recv_sec - send_sec
        delay = delay * 1000
        Delay_Sum[send_node - 1] += delay

log_file = open('log.txt','r')
while 1:
    line = log_file.readline()
    cut_line(line)
    if not line:
        break

tot_send = 0
tot_succ = 0
tot_delay = 0

print "-------------------------------------------------------------"

print "Analysis Result:"
for i in range(6):
    print ('Node %d : Packet Loss Rate = %.2f%% Average Delay = %.2f ms' %
           (i+1, (1 - 1.0 * Send_Succ[i] / Send[i]) * 100, 1.0 * Delay_Sum[i] / Send_Succ[i]))
    tot_send += Send[i]
    tot_succ += Send_Succ[i]
    tot_delay += Delay_Sum[i]
print ''
print 'Overall : Packet Loss Rate = %.2f%% Average Delay = %.2f ms' % ((1-1.0*tot_succ / tot_send) * 100, 1.0 * tot_delay / tot_succ)

