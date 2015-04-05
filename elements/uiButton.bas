' uiButton.bas - Do what the f... you want (WTFPL). 
' Author: StringEpsilon, 2015

#include once "../common/uiElement.bas"
#include once "fbthread.bi"

type uiButton extends uiElement
	protected:
		dim as string _Label
		dim as bool _hold
	public:
		dim as bool IsChecked = true
		
		declare virtual function Render() as fb.image  ptr
		declare virtual sub OnClick( mouse as uiMouseEvent)	
		declare virtual sub Onfocus( focus as bool)
		
		declare constructor overload( x as integer, y as integer, newLabel as string = "")
		declare constructor(dimensions as uiDimensions, newLabel as string = "")

		declare property Label() as string
		declare property Label(value as string)
end type

constructor uiButton( x as integer, y as integer, newLabel as string = "")
	base()
	with this._dimensions
		.h = 18
		.w = 20 + (len(newlabel)*7)
		.x = x
		.y = y
	end with
	this._label = newLabel
	this.CreateBuffer()
end constructor

constructor uiButton(newdim as uiDimensions, newLabel as string = "")
	base()
	this._dimensions = newdim
	this.CreateBuffer()
end constructor

property uiButton.Label(value as string)
	if ( len(value) <= ( this._dimensions.w - 20 ) / 7 ) then 
		mutexlock(this._mutex)
		this._label = value
		mutexunlock(this._mutex)
	else
		mutexlock(this._mutex)
		this._label = value
		this._dimensions.w = 20 + len(value)*7
		this.CreateBuffer()
		mutexunlock(this._mutex)
	end if
	this.DoRedraw()
end property

property uiButton.Label() as string
	return this._label
end property

function uiButton.Render() as fb.image  ptr
	with this._dimensions
		DrawButton(this._cairo,.w,.h, this._Hold)
		DrawLabel(this._cairo,10, (.h - CAIRO_FONTSIZE)/2, this._Label)
	end with
	return this._buffer
end function

sub uiButton.OnClick( mouse as uiMouseEvent )
	if ( mouse.lmb = released  ) then
		mutexlock(this._mutex)
		this._hold = false
		mutexunlock(this._mutex)
		if ( this.callback <> 0 ) then
			threaddetach(threadcreate(this.callback, @this))
		end if
		base.DoRedraw()
	elseif ( mouse.lmb = hit OR mouse.lmb = hold ) then
		mutexlock(this._mutex)
		this._hold = true
		mutexunlock(this._mutex)
		base.DoRedraw()
	end if
end sub


sub uiButton.OnFocus( focus as bool )
	if (focus = false) then
		this._hold = false
		base.DoRedraw()
	end if
end sub
