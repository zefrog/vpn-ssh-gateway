#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         Francois Laplaud



#ce ----------------------------------------------------------------------------
#include <File.au3>
#include <MsgBoxConstants.au3>

Const $strRegAddTemplate = @ScriptDir & "\registry_add_template.reg"
Const $strRegDelTemplate = @ScriptDir & "\registry_del_template.reg"
Const $strWINTITLE = "temporary_session_for_vpn-ssh-gateway"
Const $strPatternHostname = "###HOSTNAME"
Const $strPatternUsername = "###USERNAME"
Const $strPatternPort = "###PORTSSH"
Const $strPatternSession = "###SESSION"
Const $strPatternPortForwarding = "###PORTWORWARDING"
Const $strPatternPubKey = "###PUBKEY"

Global $localPortMin = 10000
Global $localPortMax = 65534
Global $localUsedPorts = ""
Global $strHost, $strSSHPort, $strSession, $strUsername, $strPassword, $strPubKey, $strPortForwarding ; Will be generated from getConfig
Global $arrTunnels[1] ; Will be generated from getConfig

Func Main()
	getConfig()
	KillWindowName($strWINTITLE)
	genPuttyConfig($strHost, $strSSHPort, $strSession, $strUsername, $strPubKey)
	addSSHRegFile($strSession)
	startSSHTunnel($strSession)
	MsgBox(0,"","Tunnel Established, Forwarded List : " & $strPortForwarding,60)
	Sleep(3000)

	delSSHRegFile($strSession)
EndFunc




Func startSSHTunnel($strSession)
	Run(@ScriptDir & "\putty.exe -load " & $strSession,"",@SW_MAXIMIZE)
EndFunc

Func addSSHRegFile($strSession)
	RunWait("regedit.exe /s " & chr(34)  & getAddRegConfigName($strSession) & chr(34),"",@SW_HIDE)
EndFunc
Func delSSHRegFile($strSession)
	RunWait("regedit.exe /s " & getDelRegConfigName($strSession),"",@SW_HIDE)
EndFunc

Func getAddRegConfigName($strSession)
	return @ScriptDir & "\" & $strSession & "-add.reg"
EndFunc
Func getDelRegConfigName($strSession)
	return @ScriptDir & "\" & $strSession & "-del.reg"
EndFunc

Func genPuttyConfig($strHost, $strSSHPort, $strSession, $strUsername, $strPubKey)
	Local $strRegAddFilename = getAddRegConfigName($strSession)
	Local $strRegDelFilename = getDelRegConfigName($strSession)
	For $arrTunnel in $arrTunnels
		$strPortForwarding = genTunnelSetting($arrTunnel) & "," & $strPortForwarding
	Next
	FileCopy($strRegAddTemplate, $strRegAddFilename ,1)
	_ReplacestringInFile($strRegAddFilename, $strPatternHostname, $strHost, 0, 1)
	_ReplacestringInFile($strRegAddFilename, $strPatternUsername, $strUsername, 0, 1)
	_ReplacestringInFile($strRegAddFilename, $strPatternPort, intToRegistryDWORD(int($strSSHPort)), 0, 1)
	_ReplacestringInFile($strRegAddFilename, $strPatternSession, $strSession, 0, 1)
	_ReplacestringInFile($strRegAddFilename, $strPatternPortForwarding, $strPortForwarding, 0, 1)
	_ReplacestringInFile($strRegAddFilename, $strPatternPubKey, pathToRegistryString($strPubKey), 0, 1)
	FileCopy($strRegDelTemplate, $strRegDelFilename ,1)
	_ReplacestringInFile($strRegDelFilename, $strPatternSession, $strSession, 0, 1)
EndFunc

Func pathToRegistryString($str)
	return StringReplace($str,"\","\\", 0)
EndFunc
Func intToRegistryDWORD($intNumber)
	Local $strDword
	$strDword = "dword:0"
	if IsInt($intNumber) Then
		$strDword = $strDword & hex($intNumber)
	EndIf
	Return $strDword
EndFunc

Func GetConfig()
	; For Now, all data is static for testing
	; Next, data will be retrieved from a remote WebService in a structured JSON format
	$strHost = "192.168.103.210"
	$strSSHPort = 22
	$strSession = "temporary_session_for_vpn-ssh-gateway"
	$strUsername = "tunneltest"
	$strPassword = "tunneltest"
	$strPubKey = @ScriptDir & "\user.ppk"
	_ArrayAdd($arrTunnels, "10.172.1.21:23")
	_ArrayAdd($arrTunnels, "10.172.1.20:23")
	_ArrayAdd($arrTunnels, "192.168.100.4:3389")
	_ArrayDelete($arrTunnels,0) ; AutoIt doesn't handle empty array definition, so we defined an aray with 1 empty element, we remove this element so that iterating through the Array won't work properly

EndFunc

Func CheckLocalPortAvailable($intPort)
	OnAutoItExitRegister("OnAutoItExit")
	TCPStartup()
	Local $sIPAddress = "0.0.0.0"

    Local $iListenSocket = TCPListen($sIPAddress, $intPort, 5)
    ; If an error occurred display the error code and return False.
    If @error Then
        ; Someone is probably already listening on this IP Address and Port (script already running?).
        Local $iError = @error
        MsgBox(BitOR($MB_SYSTEMMODAL, $MB_ICONHAND), "VPN SSH Gateway", "Could not listen to port " & $intPort & ", Error code: " & $iError, 2)
		TCPCloseSocket($iListenSocket)
		TCPShutdown() ; Close the TCP service.
        Return False
    Else
        TCPCloseSocket($iListenSocket)
		TCPShutdown() ; Close the TCP service.
		Return True
    EndIf

EndFunc
Func OnAutoItExit()
    TCPShutdown() ; Close the TCP service.
EndFunc   ;==>OnAutoItExit

Func KillWindowName($strWinTitle)
	While WinExists( $strWinTitle )
		ProcessClose(WinGetProcess( $strWinTitle ))
		Sleep(100)
	WEnd
EndFunc

Func genTunnelSetting($strIPPort)
	Local $lPort

	; Generate random port number
	while 1
		$lPort = Random($localPortMin, $localPortMax, 1)
		ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : lPort  = ' & $lPort  & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
		If StringInStr($localUsedPorts, $lPort) = 0 Then ; If the lPort Randomly generated have previously been choosen we discard this choice
			; check if port is Available for listening
			if CheckLocalPortAvailable($lPort) then ExitLoop
		EndIf
	WEnd
		; Generate Tunnel String and save lPort so that it wont be usable again
	$localUsedPorts = $localUsedPorts & ";" & $lPort
	return "L" & $lPort & "=" & $strIPPort
EndFunc

Main()