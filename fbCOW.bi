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
		refCount as uinteger
		stringPtr as fbstring ptr
		
		declare constructor()
		declare destructor()
end type

constructor fbCOWItem()
	this.stringPtr = new fbstring
end constructor

destructor fbCOWItem()
	this.refCount -= 1
	if ( this.refCount < 1 ) then
		deallocate(this.stringPtr->stringData)
		deallocate(this.stringPtr)
	end if
end destructor

type fbCOW 
	private: 
		_payload as fbCOWItem ptr
	public:
		declare constructor()
		declare constructor(byref value as string)
		
		declare destructor()
		
		declare operator LET(copy as fbCOW)
		declare operator cast() as string
		declare operator +=(value as string)
		
		declare operator [](index as uinteger) as ubyte		
		declare function length() as integer
end type

constructor fbCOW(byref value as string)
	this._payload = new fbCowItem
	dim source as fbString ptr = cast(fbString ptr, @value)
	
	this._payload->stringPtr->size = source->size
	this._payload->stringPtr->length = source->length
	this._payload->stringPtr->stringData = allocate(source->size)
	
	memcpy( this._payload->stringPtr->stringData, source->stringData, source->size )
end constructor

constructor fbCOW()
	
end constructor

destructor fbCOW()
	if ( this._payload = 0) then return 
	
	if ( this._payload->refcount = 0) then
		delete this._payload
	else
		this._payload->destructor
	end if
end destructor

operator fbCOW.cast() as string
	return *(cast(string ptr, this._payload->stringPtr))
end operator

operator fbCOW.let(copy as fbCOW) 
	if ( this._payload <> 0 ) then
		this._payload->destructor
	end if
	
	this._payload = copy._payload
	this._payload->refCount += 1
end operator

operator fbCOW.+= (value as string)
	dim valuePtr as fbstring ptr = cast(fbstring ptr, @value)
	dim newData as fbString ptr = new fbString

	newData->length = this._payload->stringPtr->length + valuePtr->length
	
	' Strings in FB have more allocated memory than their reported length. 
	if ( this._payload->stringPtr->size < newData->length ) then
		newData->size = this._payload->stringPtr->size + valuePtr->size
	else
		newData->size = this._payload->stringPtr->size
	end if
	
	newData->stringData = allocate( newData->size)
	
	memcpy( newData->stringData, this._payload->stringPtr->StringData, this._payload->stringPtr->length )
	memcpy( newData->stringData + this._payload->stringPtr->length, valuePtr->StringData, valuePtr->length )
	this._payload->refCount -= 1
	this._payload = new fbCowItem
	this._payload->refcount += 1
	this._payload->stringPtr = newData
	
end operator

operator fbCOW.[](index as uinteger) as ubyte
	return this._payload->stringPtr->stringData[index]
end operator

function fbCOW.length() as integer
	return this._payload->stringPtr->length
end function

operator len(cow as fbCOW) as integer
	return cow.length()
end operator
