' uiScrollBar.bas - Do what the f... you want (WTFPL). 
' Author: StringEpsilon, 2015

#include once "../common/uiElement.bas"
#define uiCeil(d) (-Int(-d))

type uiScrollbarKnob
	Size as double
	Position as double = 0
end type

enum uiOrientation
	vertical = 0
	horizontal = 1
end enum

type uiScrollBar extends uiElement
	private:
		_min as integer
		_range as integer
		_segments as integer
		_value as integer
		_knob as uiScrollbarKnob
		_hold as bool = false
		_orientation as uiOrientation
		declare sub CalculateValue(position as integer)
	public:
		declare function Render() as cairo_surface_t  ptr
		
		declare constructor overload(x as integer, y as integer, size as integer, max as integer, min as integer = 1, range as integer = 1, orientation as uiOrientation = vertical)
		declare property Value() as integer
		declare property Value(newValue as integer)
		
		declare virtual sub OnMouseMove( mouse as uiMouseEvent )
		declare virtual sub OnClick( mouse as uiMouseEvent ) 
end type

constructor uiScrollBar(x as integer, y as integer, size as integer, max as integer, min as integer = 1, range as integer = 1, orientation as uiOrientation = vertical)
	base()
	with this._dimensions
		.h = IIF(orientation = vertical,size,10)
		.w = IIF(orientation = horizontal,size,10)
		.x = x
		.y = y
	end with
	this._min = min
	this._value = this._min
	this._range = IIF(range > 0, range, 1)
	this._orientation = orientation
	this._segments = uiCeil((max - this._min + 1 ) / this._range)
	this._knob.Size = size / this._segments
	this.CreateBuffer()
end constructor

property uiScrollBar.Value() as integer
	return this._value * this._range
end property


property uiScrollBar.Value(newValue as integer)
	mutexlock(this._mutex)
	this._value = newValue
	mutexunlock(this._mutex)
	this.Redraw()
end property

sub uiScrollBar.OnMouseMove( mouse as uiMouseEvent )
	if (mouse.lmb = hit  OR mouse.lmb = hold and this._hold) then
		if (this._orientation = vertical) then
			mutexlock(this._mutex)
			dim y as integer = mouse.y - this._dimensions.y 
			if ( y > 0 and y < this._dimensions.h) then
				this.CalculateValue(y)
			end if
			mutexunlock(this._mutex)
		else
			mutexlock(this._mutex)
			dim x as integer = mouse.x - this._dimensions.x 
			if ( x > 0 and x < this._dimensions.w) then
				this.CalculateValue(x)
			end if
			mutexunlock(this._mutex)
		end if
	end if
end sub

sub uiScrollBar.CalculateValue(position as integer)
	dim as integer l = IIF(this._orientation=vertical,this.dimensions.h, this.dimensions.w)
	dim as integer newValue =  int( position / (l+1) * this._segments)  + this._min
	if (this._value <> newValue ) then
		this._value = newValue 
		this._knob.Position = (this._knob.Size * (this._value - this._min))
		this.Redraw()
		
		if (this.callback <> 0) then
			threaddetach(threadcreate(this.callback, @this))
		end if
	end if
end sub

sub uiScrollBar.OnClick( mouse as uiMouseEvent )
	dim p as integer = IIF(this._orientation=vertical, mouse.y - this._dimensions.y, mouse.x - this._dimensions.x)
	if ( mouse.lmb = hit ) then
		if (p >= this._knob.Position and p <= this._knob.Position + this._knob.Size) then
			this._hold = true
		end if
	elseif ( mouse.lmb = released ) then
		this._hold = false
		if (p < this._knob.Position or p > this._knob.Position + this._knob.Size) then
			this.CalculateValue(p)
		end if
	else
		this._hold = false
	end if
end sub

function uiScrollBar.Render() as cairo_surface_t  ptr
	with this._dimensions
		cairo_set_source_rgb(this._cairo,RGBA_R(ElementLight),RGBA_G(ElementLight),RGBA_B(ElementLight))
		cairo_paint(this._cairo)
		cairo_rectangle (this._cairo, .5, .5, .w-1, .h-1)
		cairo_set_line_width(this._cairo, 1)
		cairo_set_source_rgb(this._cairo,0,0,0)
		
		cairo_stroke (this._cairo)
		if (this._orientation = vertical) then
			cairo_rectangle(this._cairo, .5, this._knob.Position+.5, .w-1,this._knob.Size)
		else
			cairo_rectangle(this._cairo, this._knob.Position+.5, .5, this._knob.Size, .h-1)
			shell "echo knob: "& this._knob.position & " " & this._knob.Size
		end if
		cairo_stroke_preserve (this._cairo)
		cairo_set_source_rgb(this._cairo,RGBA_R(ElementDark),RGBA_G(ElementDark),RGBA_B(ElementDark))
		cairo_fill(this._cairo)		
	end with
	return this._surface
end function
