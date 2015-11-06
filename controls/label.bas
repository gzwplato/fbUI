' uiLabel.bas - StringEpsilon, 2015, WTFPL

#include once "../common/control.bas"

namespace fbUI

type uiLabel extends uiControl
	private:
		_Text as string 
	public:
		declare function Render() as fb.image ptr
		
		declare constructor overload( x as integer, y as integer, newText as string,  length as integer = 0)

		declare property Text() as string
		declare property Text(value as string)
end type

constructor uiLabel( x as integer, y as integer,newText as string,  length as integer = 0)
	base()	
	with this._dimensions
		.h = 16
		.w = 4 + IIF(length = 0, len(newText) * FONT_HEIGHT, length * FONT_WIDTH)
		.x = x
		.y = y
	end with
	this._text = newText
	this.CreateBuffer()
end constructor

property uiLabel.Text(value as string)
	mutexlock(this._mutex)
	this._text = value
	mutexunlock(this._mutex)
	this.Redraw()
end property

property uiLabel.Text() as string
	return this._Text
end property

function uiLabel.Render() as fb.image ptr
	if ( this._stateChanged ) then
		with this._dimensions
			
			if (len(this._text) <> 0) then	
				draw string this._surface, (1, (.h - FONT_HEIGHT) / 2 ), this._text, ElementTextColor
			end if
		end with
		this._stateChanged = false
	end if
	return this._surface
end function

end namespace
