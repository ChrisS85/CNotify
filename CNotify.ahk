SetBatchlines, -1
SetWinDelay, -1
Loop 4
{
	window := new CNotificationWindow("Test rhabarberbabarababarenbarbierbierbar", A_Index ": <A ID=""bla"">test</A>", A_AHKPath, 5000 * A_Index, new Delegate("Handler"))
	Sleep 100
}
return
handler(URLorID = "", Index = "")
{
	msgbox % URLorID " and " Index
}
#include <CGUI>

Class CNotification
{
	static Windows := Array()
	;Default style used for a notification window. An instance can be supplied to the constructor to use a specific style
	Class CStyle
	{

	}

	;Class used to describe a progress bar in a notification window. Can be passed to the constructor to show a progress bar
	Class CProgress
	{
		Min := 0
		Max := 100
		Value := 0
		Text := 0
		__new(Min, Max, Value)
		{
			this.Min := Min
			this.Max := Max
			this.Value := Value
		}
	}
	RegisterNotificationWindow(NotificationWindow)
	{
		;msgbox % this.Windows.MaxIndex() ": " this.Windows[this.Windows.MaxIndex()].Y
		if(this.Windows.MaxIndex())
			Y := this.Windows[this.Windows.MaxIndex()].Y - NotificationWindow.WindowHeight
		else
		{
			SysGet, Mon, MonitorWorkArea, %mon%
			this.WorkspaceArea := {Left: MonLeft, Top : MonTop, Right : MonRight, Bottom : MonBottom}
			Y := this.WorkspaceArea.Bottom - NotificationWindow.WindowHeight
		}
		this.Windows.Insert(NotificationWindow)
		;msgbox % objmaxindex(this.Windows)
		NotificationWindow.OnClose.Handler := new Delegate(this, "OnClose")
		if(NotificationWindow.Timeout)
			SetTimer, CNotification_CloseTimer, -10
		return {X : this.WorkspaceArea.Right - NotificationWindow.WindowWidth, Y : Y}
	}
	OnClose(Sender)
	{
		for index, Window in this.Windows
		{
			if(Window = Sender)
			{
				this.Windows.Remove(Index)
				this.CalculateTargetPositions()
				SetTimer, CNotification_MoveWindows, -10
				return
			}
		}
	}
	CalculateTargetPositions()
	{
		Target := this.WorkspaceArea.Bottom
		Loop % this.Windows.MaxIndex()
		{
			;msgbox % "Window " A_Index ": " Target - this.Windows[A_Index].WindowHeight
			Target := this.Windows[A_Index].Target := Target - this.Windows[A_Index].WindowHeight
		}
	}
	MoveWindows()
	{
		Moved := false
		for index, Window in this.Windows
		{
			hwnd := Window.hwnd
			WinGetPos, , Y, , , ahk_id %hwnd%
			;Y := Window.Y
			if((Distance := Window.Target - Y) > 0)
			{
				Moved := true
				Delta := (Distance > 50 ? 5 : Round(5 - 5/Distance))
				Delta := Delta > Distance ? Distance : Delta
				WinMove, ahk_id %hwnd%, , , % Y + Delta
				;Window.Y := Y + (Distance > 50 ? 5 : Round(5 - 5/Distance))
			}
		}
		if(Moved)
			SetTimer, CNotification_MoveWindows, -10
	}
	CloseTimer()
	{
		StillWaiting := false
		for index, Window in this.Windows
		{
			if(Window.Timeout && A_TickCount > Window.CloseTime)
			{
				Window.Remove("Timeout")
				Window.Close()
				continue
			}
			if(Window.Timeout)
				StillWaiting := true
		}
		if(StillWaiting)
			SetTimer, CNotification_CloseTimer, -10
	}
}
CNotification_MoveWindows:
CNotification.MoveWindows()
return
CNotification_CloseTimer:
CNotification.CloseTimer()
return

Class CNotificationWindow Extends CGUI
{
	OnClick := new EventHandler()

	/*Creates a new notification. Parameters:
	Title: Title
	Text: Text. Supports links in markup language, see link control
	Icon: Path or icon handle
	Timeout: Empty for no timeout, otherwise timeout in ms.
	OnClick: function or delegate to handle clicks on the notification. It can optionally accept two arguments that indicate the clicked link, URLorID and Index.
	Progress: See CNotification.CProgress
	Style: See CNotification.CStyle
	*/

	__new(Title, Text, Icon = "", Timeout = "", OnClick = "", Progress = "", Style = "")
	{
		this.Timeout := Timeout
		this.CloseTime := A_TickCount + Timeout
		this.OnClick.Handler := OnClick
		this.AlwaysOnTop := true
		this.Border := false

		this.AddControl("Text", "txtTitle", "", Title)
		if(Progress)
		{
			this.AddControl("Progress", "prgProgress", "Range" Progress.Min "-" Progress.Max, Progress.Value)
			if(Progress.Text)
				this.AddControl("Text", "txtProgress", "", Progress.Text)
		}
		if(Icon)
		{
			this.AddControl("Picture", "icoIcon", "", Icon)
		}
		this.AddControl("Link", "lnkText", Icon ? "x+10" : "", Text)

		this.Position := CNotification.RegisterNotificationWindow(this)
		this.Show()

		;Background text control to detect clicks on the GUI
		this.AddControl("Text", "txtBackground", "x0 y0 w" this.Width " h" this.Height " BackgroundTrans")

		;Register handlers for all controls
		for index, control in this.Controls
			if(control.Type != "Progress" && control.Type != "Link")
				control.Click.Handler := new Delegate(this, "Click")
	}
	Click()
	{
		this.OnClick.()
		this.Close()
	}
	lnkText_Click(URLOrID, Index)
	{
		this.OnClick.(URLOrID, Index)
		this.Close()
	}
}