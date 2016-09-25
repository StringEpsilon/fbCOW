#include once "fbCOW.bi"

sub StressTestCow(value as string, count as uinteger)
	dim array(count) as fbCow
	dim original as fbCow = value
	for i as integer = 1 to count
		array(i) = original
	next
end sub

sub StressTestString(value as string, count as uinteger)
	dim array(count) as string
	dim original as string = value
	for i as integer = 1 to count
		array(i) = original
	next
end sub


dim as double t1, t2
t1 = timer
StressTestCow("Hello World", 10000000)
t2 = timer

print t2 - t1

t1 = timer
StressTestString("Hello World", 10000000)
t2 = timer

print t2 - t1
