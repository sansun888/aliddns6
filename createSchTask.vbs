Dim Fso, Ws, ext, shpg, cmdstr, rungap, shcmd

' Author: tyasky

rungap = 5      ' �������м��������

Set Fso = CreateObject("Scripting.FileSystemObject")
Set Ws = WScript.CreateObject("Wscript.Shell")

If WScript.Arguments.Length>=1 Then
	shcmd = WScript.Arguments(0)
Else
	shcmd = InputBox("����Ҫִ�е� bash �ű���","�ƻ�����")
	If shcmd = "" Then WScript.Quit
End If

ext= Ws.RegRead("HKEY_CLASSES_ROOT\.sh\")
shpg = Split(Ws.RegRead("HKEY_CLASSES_ROOT\" & ext & "\shell\open\command\"), """")(1)
shpg = Fso.GetFile(shpg).ShortPath

cmdstr = shpg & " --hide " & shcmd

Ws.Run "cmd /c SCHTASKS /Create /TN aliddns /SC MINUTE /MO " & rungap & " /TR  """ & cmdstr & """", 0

MsgBox "�ű�������ϡ�",, "^_^"
WScript.Quit(0)
