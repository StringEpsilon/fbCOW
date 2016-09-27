/'	
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/. 
'/

#include "crt.bi"

type fbString
    dim as byte ptr stringData 
    dim as uinteger length
    dim as uinteger size
end type

type fbCOWItem

	public:
		refCount as integer
		stringPtr as fbstring ptr
		ref as fbCowItem ptr
		
		declare constructor()
		declare destructor()
end type

constructor fbCOWItem()
	'this.stringPtr = new fbstring
	this.refcount = 1
end constructor

destructor fbCOWItem()
	if ( this.ref <> 0 ) then
		ref->refcount -= 1
		delete this.stringPtr
		if ( ref->refcount = 0) then
			delete ref
		end if
	else
		if ( this.refCount = 0 ) then
			deallocate(this.stringPtr->stringData)
			deallocate(this.stringPtr)	
		end if
	end if
end destructor

type fbCOW
	private: 
		_payload as fbCOWItem ptr = 0
	
	public:
		declare constructor()
		declare constructor(byref value as string)
		declare constructor(byref value as fbCow)
		
		declare destructor()
		
		declare operator LET(copy as fbCOW)
		declare operator cast() as string
		declare operator +=(value as string)
		
		declare operator [](index as uinteger) as ubyte		
		
		declare function length() as integer
		
		declare function equals overload (value as fbCOW) as boolean 
		declare function equals(value as string) as boolean
		
		declare function MID(start as uinteger, l as uinteger) as fbCow
		declare function MIDtoString(start as uinteger, l as uinteger) as string
end type

constructor fbCOW(byref value as string)
	this._payload = new fbCowItem
	dim source as fbString ptr = cast(fbString ptr, @value)
	
	this._payload->stringPtr = new fbstring
	this._payload->stringPtr->size = source->size
	this._payload->stringPtr->length = source->length
	this._payload->stringPtr->stringData = allocate(source->size)
	
	memcpy( this._payload->stringPtr->stringData, source->stringData, source->size )
end constructor

constructor fbCOW(byref value as fbCOW)
	this._payload = value._payload
	value._payload->refCount += 1
end constructor

constructor fbCOW()
	
end constructor

destructor fbCOW()
	if ( this._payload = 0) then return 
	
	this._payload->refCount -= 1
	if ( this._payload->refcount <= 0) then
		delete this._payload
	end if	
	this._payload = 0
end destructor

operator fbCOW.cast() as string
	if (this._payload = 0) then return ""
	return *(cast(string ptr, this._payload->stringPtr))
end operator

operator fbCOW.let(copy as fbCOW) 
	this.destructor
	if ( copy._payload <> 0) then
		this._payload = copy._payload
		this._payload->refCount += 1
	end if
end operator

operator =(A as fbCOW, b as fbCOw) as boolean
	return a.equals(b)
end operator

operator =(A as fbCOW, b as string) as boolean
	return a.equals(b)
end operator

operator fbCOW.+= (value as string)
	dim valuePtr as fbstring ptr = cast(fbstring ptr, @value)
	dim newData as fbString ptr = new fbString

	newData->length = this._payload->stringPtr->length + valuePtr->length
	newData->size = newData->length 	
	newData->stringData = allocate( newData->size)
	
	memcpy( newData->stringData, this._payload->stringPtr->StringData, this._payload->stringPtr->length )
	memcpy( newData->stringData + this._payload->stringPtr->length, valuePtr->StringData, valuePtr->length )
	this.destructor()
	this._payload = new fbCowItem
	this._payload->stringPtr = newData
end operator

operator fbCOW.[](index as uinteger) as ubyte
	return this._payload->stringPtr->stringData[index]
end operator

operator len(cow as fbCOW) as integer
	return cow.length()
end operator

' Public functions

function fbCOW.length() as integer
	return this._payload->stringPtr->length
end function

function fbCOw.Equals(value as fbCow) as boolean
	dim result as boolean = this._payload = value._payload
	if result = true then 
		return true
	else
		return cast(string, value) = cast(string, this)
	end if
end function

function fbCOw.Equals(value as string) as boolean
	dim as string tempstring = this
	return tempstring = value
end function

function fbCow.MID(start as uinteger, l as uinteger) as fbCOW
	if ( start > this.length ) then
		return fbCow()
	end if
	
	if ( start + l > this.length ) then
		l = this.length - start
	end if
	
	dim result as fbCOW 'ptr = new fbCow()
	this._payload->refcount += 1
	
	result._payload = new fbCowItem()
	result._payload->stringPtr = new fbString
	result._payload->ref = this._payload
	
	result._payload->stringPtr->length = l
	result._payload->stringPtr->size = l
	result._payload->stringPtr->stringData = this._payload->stringPtr->stringData + start
	return result
end function

function fbCow.MIDtoString(start as uinteger, l as uinteger) as string
	if ( start > this.length ) then
		return fbCow()
	end if
	
	if ( start + l > this.length ) then
		l = this.length - start
	end if
	
	dim result as string
	dim resultPtr as fbString ptr = cast(fbstring ptr, @result)
	
	resultPtr->length = l
	resultPtr->size = l
	resultPtr->stringData = allocate(resultPtr->size)
	memcpy( resultPtr->stringData, this._payload->stringPtr->stringData + start, resultPtr->size )
	return result
end function
