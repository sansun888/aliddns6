Dim Fso, Ws, ext, shpg, cmdstr, rungap, conf, cwd, fp

' Author: tyasky

rungap = 5      ' �������м��������

Set Fso = CreateObject("Scripting.FileSystemObject")
Set Ws = WScript.CreateObject("Wscript.Shell")

If WScript.Arguments.Length>=1 Then
	conf = WScript.Arguments(0)
Else
	conf = InputBox("���������ļ�·����","�ƻ�����")
	If conf = "" Then WScript.Quit
End If

ext= Ws.RegRead("HKEY_CLASSES_ROOT\.sh\")
shpg = Split(Ws.RegRead("HKEY_CLASSES_ROOT\" & ext & "\shell\open\command\"), """")(1)
shpg = Fso.GetFile(shpg).ShortPath

cwd = Fso.GetParentFolderName(WScript.ScriptFullName)
fp = Fso.BuildPath(cwd, "aliddns.sh")
fp = Fso.GetFile(fp).ShortPath

conf = Fso.GetFile(conf).ShortPath
cmdstr = shpg & " --hide " & fp & " -f " & conf

Ws.Run "cmd /c SCHTASKS /Create /TN aliddns /SC MINUTE /MO " & rungap & " /TR  """ & cmdstr & """", 0

MsgBox "�ű�������ϡ�",, "^_^"
WScript.Quit(0)
