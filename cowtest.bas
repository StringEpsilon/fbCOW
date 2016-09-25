#include once "fbCOW.bi"

dim test as fbCOW = "Hello World"
dim copy as fbCOW 
dim copy2 as fbCOW 
copy = test
copy2 = test
dim as string test2 = test

test += "!"
print test
print test2
print copy
print strptr(test2)

'test += "!"
print test
print test2
print copy
