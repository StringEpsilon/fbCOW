/'	
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/. 
'/

#include "crt.bi"

#ifndef fbString
type fbString
    dim as byte ptr stringData 
    dim as uinteger length
    dim as uinteger size
end type
#endif

type fbCOWItem

	public:
		refCount as integer
		stringPtr as fbstring ptr
		ref as fbCowItem ptr
		
		declare constructor()
		declare destructor()
end type

constructor fbCOWItem()
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
		declare function ShadowCopy(stringLength as uinteger = 0) as fbCowItem ptr
	
	public:
		declare constructor()
		declare constructor(byref value as string)
		declare constructor(byref value as fbCow)
		
		declare destructor()
		
		declare operator LET(copy as fbCOW)
		declare operator cast() as string
		declare operator +=(value as string)
		
		declare operator [](index as uinteger) as ubyte		
		
		declare function GetLength() as integer
		
		declare function Equals overload (byref value as fbCOW) as boolean 
		declare function Equals(byref value as string) as boolean
		
		declare function Mid(start as uinteger, length as uinteger) as fbCow
		declare function Left(length as uinteger) as fbCow
		declare function Right(length as uinteger) as fbCow
		declare function LeftString(length as uinteger) as string
		declare function RightString(length as uinteger) as string
		declare function MIDString(start as uinteger, length as uinteger) as string
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
	if ( this._payload->refcount = 0) then
		delete this._payload
	end if	
	this._payload = 0
end destructor

operator fbCOW.cast() as string
	if (this._payload = 0) then return ""
	return *(cast(string ptr, this._payload->stringPtr))
end operator

operator fbCOW.let(copy as fbCOW) 
	if (this._payload <> 0) then this.destructor()
	
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
	dim length as uinteger = IIF(this._payload <> 0, this._payload->stringPtr->length, 0)
	
	newData->length = length + valuePtr->length
	newData->size = newData->length
	newData->stringData = allocate( newData->size)
	
	if (length <> 0) then
		memcpy( newData->stringData, this._payload->stringPtr->StringData, length )
	end if
	memcpy( newData->stringData + length, valuePtr->StringData, valuePtr->length )
	this.destructor()
	this._payload = new fbCowItem
	this._payload->stringPtr = newData
end operator

operator fbCOW.[](index as uinteger) as ubyte
	return this._payload->stringPtr->stringData[index]
end operator

operator len(cow as fbCOW) as integer
	return cow.getLength()
end operator

' Private functions

function fbCow.ShadowCopy(stringLength as uinteger = 0) as fbCowItem ptr
	dim result as fbCowItem ptr
	
	this._payload->refcount += 1
	
	result = new fbCowItem()
	result->stringPtr = new fbString
	result->ref = this._payload
	
	result->stringPtr->length = stringLength
	result->stringPtr->size = stringLength
	result->stringPtr->stringData = this._payload->stringPtr->stringData
	return result
end function

' Public functions

function fbCOW.GetLength() as integer
	return this._payload->stringPtr->length
end function

function fbCOw.Equals(byref value as fbCow) as boolean
	if this._payload = value._payload then 
		return true
	else
		if(strcmp(value._payload->stringPtr->stringData, this._payload->stringPtr->stringData) = 0) then
			return true
		end if
	end if
	return false
end function

function fbCOw.Equals(byref value as string) as boolean
	if strcmp(strptr(value), this._payload->stringPtr->stringData) = 0 then
		return true
	end if
	return false
end function

function fbCow.MID(start as uinteger, length as uinteger) as fbCOW
	if (start = 0) then return fbCow()
	
	start -=1 ' start is the first included(!) character. Going -1 makes stuff easier.
	if ( start > this.GetLength() ) then
		return fbCow()
	end if
	
	if ( start + length > this._payload->stringPtr->length ) then
		length = this._payload->stringPtr->length - start
	end if
	
	dim result as fbCOW
	result._payload = this.ShadowCopy(length) 
	result._payload->stringPtr->stringData += start
	return result
end function

function fbCow.Left(length as uinteger) as fbCOW
	if ( length >= this.GetLength() ) then
		return fbCow(this)
	end if
	
	dim result as fbCOW
	result._payload = this.ShadowCopy(length) 
	return result
end function


function fbCow.LeftString(length as uinteger) as string
	if ( length >= this.GetLength() ) then
		return fbCow(this)
	end if
	dim result as string
	dim resultPtr as fbString ptr = cast(fbstring ptr, @result)
	
	resultPtr->length = length
	resultPtr->size = length
	resultPtr->stringData = allocate(resultPtr->size)
	memcpy( resultPtr->stringData, this._payload->stringPtr->stringData , resultPtr->size )
	return result
end function

function fbCow.Right(length as uinteger) as fbCOW
	if ( length >= this.GetLength() ) then
		return fbCow(this)
	end if
	dim result as fbCOW
	result._payload = this.ShadowCopy(length) 
	result._payload->stringPtr->stringData += (this._payload->stringPtr->length - length)
	return result
end function

function fbCow.RightString(length as uinteger) as string
	if ( length >= this.GetLength() ) then
		return fbCow(this)
	end if
	dim result as string
	dim resultPtr as fbString ptr = cast(fbstring ptr, @result)
	
	resultPtr->length = length
	resultPtr->size = length
	resultPtr->stringData = allocate(resultPtr->size)
	memcpy( resultPtr->stringData, this._payload->stringPtr->stringData + (this._payload->stringPtr->length - length) , resultPtr->size )
	return result
end function

function fbCow.MIDString(start as uinteger, length as uinteger) as string
	start -=1
	if ( start > this.GetLength() ) then
		return fbCow()
	end if
	
	if ( start + length > this.GetLength() ) then
		length = this.GetLength - start
	end if
	
	dim result as string
	dim resultPtr as fbString ptr = cast(fbstring ptr, @result)
	
	resultPtr->length = length
	resultPtr->size = length
	resultPtr->stringData = allocate(resultPtr->size)
	memcpy( resultPtr->stringData, this._payload->stringPtr->stringData + start, resultPtr->size )
	return result
end function
