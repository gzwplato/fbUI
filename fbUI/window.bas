' window.bas - StringEpsilon, 2015, WTFPL

SCREENRES 1, 1,32,,-1

#include once "fbthread.bi"
#include once "base/buffer.bas"

namespace fbUI

#include once "uiEvents.bas"
#include once "control.bas"
#include once "base/colors.bi"

declarebuffer(IRenderable ptr, RenderableBuffer,true)

type uiWindow extends IDrawing
	private:
		static _instance as uiWindow ptr
		_mutex as any ptr
		_children as controlList ptr
		_focus as uiControl ptr
		_mouseOver as uiControl ptr
		_RenderBuffer as RenderableBuffer ptr
		_title as string
		_shutdown as boolean = false
		
		declare Constructor()
		declare Destructor()
		declare sub DrawAll()	
		declare function GetElementAt(x as integer, y as integer) as uiControl ptr
	public:
		declare property Title() as string
		declare property Title(newTitle as string)
	
		'IDrawing:
		declare virtual sub DrawElement( element as IRenderable ptr)
		
		declare static function GetInstance() as uiWindow ptr
		declare static sub DestroyInstance()
		
		declare function GetControl(id as string) as uiControl ptr
		
		declare sub CreateWindow(h as integer, w as integer, newTitle as string = "")
		declare sub HandleEvent(event as uiEvent)
		declare sub Main()
		declare sub AddControl( Control as uiControl ptr)
		declare sub RemoveControl( Control as uiControl ptr)
end type

dim uiWindow._instance as uiWindow ptr = 0

sub UIDestructor() Destructor 101
	uiWindow.DestroyInstance()
end sub

sub uiWindowEventDispatcher(event as uiEvent ptr)
	uiWindow.GetInstance()->HandleEvent(*event)
	delete event
end sub

' Dummy parameter because of threadcreate. 
sub uiWindowStart(dummyParameter as uinteger)
	uiWindow.GetInstance()->Main()
end sub

Constructor uiWindow()
	this._mutex = mutexcreate
	this._children = new ControlList()
	this._RenderBuffer = new RenderableBuffer(20)
end Constructor

Destructor uiWindow()
	for i as integer = 0 to this._children->count -1
		delete this._children->item(i)
	next
	delete this._children
	delete this._RenderBuffer
	mutexdestroy(this._mutex)
end destructor


property uiWindow.Title() as string
	return this._title
end property

property uiWindow.Title(newTitle as string)
	mutexlock(this._mutex)
	this._title = newTitle
	WindowTitle(this._title)
	mutexunlock(this._mutex)
end property

sub uiWindow.DrawAll()
	dim as uiControl ptr child
	cls
	for i as integer = 0 to this._children->count -1
		child = this._children->item(i)
		
		screenlock
		put (child->dimensions.x, child->dimensions.y), child->Render(), ALPHA
		screenunlock
	next
end sub

function uiWindow.GetElementAt(x as integer, y as integer) as uiControl ptr
	dim result as uiControl ptr = 0
	dim child as uiControl ptr
	
	for i as integer = 0 to this._children->count -1
		child = this._children->item(i)
		if child->Layer = background then 
			continue for
		end if
		with child->dimensions
			if (( x >= .x) AND ( x <= .x + .w ) and ( y >= .y) and (y <= .y + .h)) then
				if (result = 0 OrElse result->layer < child->layer) then
					result = child
				end if
			end if
		end with
	next
	return result
end function

sub uiWindow.AddControl( control as uiControl ptr)
	if (control <> 0) then
		mutexlock(this._mutex)
		' If peformance gets bad, think of a better solution...
		for i as integer = 1 to this._children->count 
			if (this._children->item(i) = control) then
				mutexunlock(this._mutex)
				exit sub
			end if
		next
		control->Parent = @this
		this._children->append(control)
		mutexunlock(this._mutex)
		this.drawelement(control)
	end if
end sub

sub uiWindow.CreateWindow(h as integer, w as integer, newTitle as string = "")
	mutexlock(this._mutex)
	this._title = newTitle
	screenres w, h, 32
	WINDOWTITLE(this._title)
	COLOR 0,BackGroundColor
	cls
		
	mutexunlock(this._mutex)
end sub

sub uiWindow.DestroyInstance()
	if (uiWindow._instance <> 0) then
		delete uiWindow._instance
	end if
end sub

sub uiWindow.RemoveControl(control as uiControl ptr)
	if (control <> 0) then
		dim i as integer = 0
		while i < this._children->count
			if ( this._children->item(i) = control) then
				mutexlock(this._mutex)
				this._children->remove(i)
				control->Parent = cast(IDrawing ptr,0)
				mutexunlock(this._mutex)
				exit while
			end if
			i += 1
		wend
		
		if (this._focus = control) then 
			mutexlock(this._mutex)
			this._focus = 0
			mutexunlock(this._mutex)
		end if
		this.DrawAll()
	end if
end sub

sub uiWindow.DrawElement( renderable as IRenderable ptr)
	if ( renderable <> 0  ) then
		this._RenderBuffer->Push(renderable)
	end if
end sub


function uiWindow.GetInstance() as uiWindow ptr
	if ( uiWindow._instance = 0 ) then
		_instance = new uiWindow()
	end if
	return _instance
end function

function uiWindow.GetControl(id as string) as uiControl ptr
	for i as integer = 0 to this._children->Count -1
		if ( this._children->Item(i)->Id = id ) then
			return this._children->Item(i)
		end if
	next
	return 0
end function

sub uiWindow.HandleEvent(event as uiEvent)
	select case as const event.eventType 
		case uiShutdown
			mutexlock(this._mutex)
			this._shutdown = true
			mutexunlock(this._mutex)
			exit sub
		case uikeyPress
			if (this._focus <> 0) then
				this._focus->OnKeypress(event.keypress)
			end if
		case uiMouseClick
			dim uiClickedElement as uiControl ptr = this.GetElementAt(event.mouse.x, event.mouse.y)
			' Always forward the release event to the element last clicked.
			
			if ( event.mouse.last = uiReleased and this._focus <> 0 ) then
				this._focus->OnClick(event.mouse)
			else
				if ( uiClickedElement <> 0 ) then
					if ( this._focus <> uiClickedElement ) then
						if (this._focus <> 0 ) then
							this._focus->OnFocus(false)
						end if
						mutexlock(this._mutex)
						this._focus = uiClickedElement
						mutexunlock(this._mutex)
						this._focus->OnFocus(true)
					end if
					uiClickedElement->OnClick(event.Mouse)
				elseif ( this._focus <> 0 ) then
					this._focus->OnFocus(false)
					mutexlock(this._mutex)
					this._focus = 0
					mutexunlock(this._mutex)
				end if
			end if
		case uiMouseMove
			mutexlock(this._mutex)
			if ( this._focus <> 0 ) then
				this._focus->OnMouseMove(event.mouse)
			end if
			mutexunlock(this._mutex)
			
			dim as uiControl ptr mouseLeave, mouseEnter
			dim uiClickedElement as uiControl ptr = this.GetElementAt(event.mouse.x, event.mouse.y)
			
			mutexlock(this._mutex)
			if ( this._mouseOver <> uiClickedElement) then
				if (this._mouseOver <> 0) then
					mouseLeave = this._mouseOver
				end if
				this._mouseOver = uiClickedElement
				if (this._mouseOver <> 0) then
					mouseEnter = this._mouseOver
				end if
			end if
			mutexunlock(this._mutex)
			
			if (mouseLeave <> 0) then mouseLeave->OnMouseLeave(event.mouse)
			if (mouseEnter <> 0) then mouseEnter->OnMouseOver(event.mouse)
		case uiMouseWheel
			if (this._focus <> 0) then
				this._focus->OnMouseWheel(event.mouse)
			elseif (this._mouseOver <> 0) then
				this._mouseOver->OnMouseWheel(event.mouse)
			end if
	end select
end sub

sub uiWindow.Main()
	this.DrawAll()
	dim eventThread as any ptr 
	dim element as IRenderable ptr
	eventThread = threadcreate(@uiEventListener, @uiWindowEventDispatcher) 
	do
		screenlock
		while this._RenderBuffer->count > 0
			element = this._RenderBuffer->Pop()
			with element->dimensions
				put (element->dimensions.x, element->dimensions.y), element->Render(), ALPHA
			end with
		wend
		screenunlock
		screensync
	loop until this._shutDown
	ThreadWait(eventThread)
end sub

end namespace
