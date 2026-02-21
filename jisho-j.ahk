#Include OCR.ahk

>!j::
{
    area := SelectArea()
    
    if (area.W < 10 or area.H < 10)
        return 

    try {
        result := OCR.FromRect(area.X, area.Y, area.W, area.H, {lang: "ja"})
    } catch as err {
        MsgBox "OCR Error: " err.Message
        return
    }

    if (result.Text != "")
    {
        cleanText := StrReplace(result.Text, " ", "")
        Run "https://jisho.org/search/" . cleanText
    }
}

SelectArea() {
    CoordMode "Mouse", "Screen"
    
    ; --- A. CURSOR SWAP ---
    hCursor := DllCall("LoadCursor", "Ptr", 0, "Int", 32515, "Ptr")
    hCopy := DllCall("CopyImage", "Ptr", hCursor, "UInt", 2, "Int", 0, "Int", 0, "UInt", 0, "Ptr")
    DllCall("SetSystemCursor", "Ptr", hCopy, "Int", 32512)

    ; --- B. DIMMING OVERLAY ---
    DimGui := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +LastFound")
    DimGui.BackColor := "000000"
    WinSetTransparent(150, DimGui.Hwnd) ; Slightly darker for better contrast
    
    vLeft := SysGet(76), vTop := SysGet(77), vW := SysGet(78), vH := SysGet(79)
    DimGui.Show("x" vLeft " y" vTop " w" vW " h" vH " NoActivate")

    ; --- C. DRAG & SPOTLIGHT LOGIC ---
    ; Wait for left click, but allow ESC to cancel
    while !GetKeyState("LButton", "P") {
        if GetKeyState("Escape", "P")
            goto Cleanup
        Sleep 10
    }
    
    MouseGetPos &startX, &startY
    
    Loop {
        if GetKeyState("Escape", "P")
            goto Cleanup
        if !GetKeyState("LButton", "P")
            break
            
        MouseGetPos &curX, &curY
        x := Min(startX, curX), y := Min(startY, curY)
        w := Abs(curX - startX), h := Abs(curY - startY)
        
        ; Create the "Hole" in the dimming GUI
        ; Outer Rect (Screen) - Inner Rect (Selection) = Spotlight
        WinSetRegion(
            "0-0 " vW "-0 " vW "-" vH " 0-" vH " 0-0 " . 
            (x-vLeft) "-" (y-vTop) " " (x-vLeft+w) "-" (y-vTop) " " (x-vLeft+w) "-" (y-vTop+h) " " (x-vLeft) "-" (y-vTop+h) " " (x-vLeft) "-" (y-vTop)
        , DimGui.Hwnd)

        Sleep 10
    }
    
    ; Success: Restore cursors and return area
    DllCall("SystemParametersInfo", "UInt", 0x0057, "UInt", 0, "Ptr", 0, "UInt", 0)
    DimGui.Destroy()
    return {X: x, Y: y, W: w, H: h}

    ; Failure/Cancel: Jump here if Esc is pressed
    Cleanup:
    DllCall("SystemParametersInfo", "UInt", 0x0057, "UInt", 0, "Ptr", 0, "UInt", 0)
    if IsSet(DimGui)
        DimGui.Destroy()
    return {X: 0, Y: 0, W: 0, H: 0}
}