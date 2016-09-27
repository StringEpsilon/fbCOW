#include once "fbCOW.bi"

sub StressTestCow(value as string, count as uinteger)
	dim array(count) as fbCow
	dim original as fbCow = value
	for i as integer = 1 to count /2
		array(i) = original
	next

	original += ", Hello Reader!"
	for i as integer = count / 2 +1 to count
		array(i) = original
	next
end sub

sub StressTestString(value as string, count as uinteger)
	dim array(count) as string
	dim original as string = value
	for i as integer = 1 to count
		array(i) = original
	next
	
	original += ", Hello Reader!"
	for i as integer = count / 2 +1 to count
		array(i) = original
	next
end sub

dim as integer count = 1000000
dim as double t1, t2
t1 = timer
StressTestCow("Hello World", count)
t2 = timer

print t2 - t1

t1 = timer
StressTestString("Hello World", count)
t2 = timer

print t2 - t1

dim as fbCOW cow = "Hello World!"
dim as string hello = "Hello World!"
print cow.Left(5) &"<"
print cow.Right(6)&"<"
print cow.Mid(7,5)&"<"

print
print left(hello, 5)&"<"
print right(hello, 6)&"<"
print Mid(hello, 7, 5)&"<"
? len(hello)
