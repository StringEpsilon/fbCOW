#include once "fbCOW.bi"

dim test as fbCOW = "Hello World"
dim as string test2 = test
print test
print test2
print strptr(test2)

test += "!"
print test
print test2
