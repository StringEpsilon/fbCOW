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

type fbCOW 
	private:
		_refCount as uinteger
		_cowRef as fbCOW ptr
		_stringPtr as fbstring ptr
	
	public:
		declare constructor()
		declare constructor(byref value as string)
		
		declare destructor()
		
		declare operator LET(copy as fbCOW)
		declare operator cast() as string
		declare operator +=(value as string)
end type

constructor fbCOW()
	
end constructor

constructor fbCOW(byref value as string)
	this._stringPtr = new fbstring
	dim source as fbString ptr = cast(fbString ptr, @value)
	
	this._stringPtr->size = source->size
	this._stringPtr->length = source->length
	this._stringPtr->stringData = allocate(source->size)
	
	memcpy( this._stringPtr->stringData, source->stringData, source->size )
end constructor

destructor fbCOW()
	' Don't destruct this, if other instances still point at it.
	if ( this._refCount = 0 ) then
		deallocate(this._stringPtr->stringData)
		deallocate(this._stringPtr)
	end if
	' If we are referencing other instances, inform them of the destruction:
	if ( this._cowRef <> 0 ) then
		this._cowRef->_refCount -= 1
		'deallocate this._stringPtr
		this._cowRef = 0
	end if
end destructor

operator fbCOW.cast() as string
	return *(cast(string ptr, this._stringPtr))
end operator

operator fbCOW.let(copy as fbCOW) 
	if ( this._stringPtr <> 0 ) then
		this.destructor()
	end if
	
	this._cowRef = @copy
	copy._refCount += 1
	
	this._stringPtr = copy._stringPtr
	
end operator

operator fbCOW.+= (value as string)
	dim valuePtr as fbstring ptr = cast(fbstring ptr, @value)
	dim newData as fbString ptr = new fbString

	newData->length = this._stringPtr->length + valuePtr->length
	
	' Strings in FB have more allocated memory than their reported length. 
	if ( this._stringPtr->size < newData->length ) then
		newData->size = this._stringPtr->size + valuePtr->size
	else
		newData->size = this._stringPtr->size
	end if
	
	newData->stringData = allocate( newData->size)
	
	memcpy( newData->stringData, this._stringPtr->StringData, this._stringPtr->length )
	memcpy( newData->stringData + this._stringPtr->length, valuePtr->StringData, valuePtr->length )
	
	this.destructor
	this._stringPtr = newData
end operator
