' uiBaseElement.bas - Do what the f... you want (WTFPL). 
' Author: StringEpsilon, 2015

type uiDimensions
	h as integer
	w as integer
	x as integer
	y as integer
	
	declare constructor overload()
	declare constructor(h as integer,w as integer,x as integer,y as integer)
end type

constructor uiDimensions()
end constructor

constructor uiDimensions(h as integer,w as integer, x as integer,y as integer)
	this.h = h
	this.w = w
	this.x = x
	this.y = y
end constructor

type IRenderable extends object
	declare abstract property Dimensions() as uiDimensions
	declare abstract function Render() as fb.image ptr
end type

type IDrawing extends object
	declare abstract sub DrawElement( element as IRenderable ptr)
end type
