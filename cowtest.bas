#include once "fbCOW.bi"

dim test as fbCOW = "Hello World"
dim copy as fbCOW = test
dim as string test2 = test

print test
print test2
print copy
print strptr(test2)

test += "!"
print test
print test2
print copy
