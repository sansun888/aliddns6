Dim Fso, Ws, ext, shpg, cwd, fp, cmdstr, rungap

' Author: tyasky

rungap = 5      ' 周期运行间隔分钟数

Set Fso = CreateObject("Scripting.FileSystemObject")
Set Ws = WScript.CreateObject("Wscript.Shell")

ext= Ws.RegRead("HKEY_CLASSES_ROOT\.sh\")
shpg = Split(Ws.RegRead("HKEY_CLASSES_ROOT\" & ext & "\shell\open\command\"), """")(1)
shpg = Fso.GetFile(shpg).ShortPath

cwd = Fso.GetParentFolderName(WScript.ScriptFullName)
fp = Fso.BuildPath(cwd, "aliddns.sh")
fp = Fso.GetFile(fp).ShortPath

cmdstr = shpg & " --hide " & fp

Ws.Run "cmd /c SCHTASKS /Create /TN aliddns /SC MINUTE /MO " & rungap & " /TR  """ & cmdstr & """", 0

MsgBox "脚本运行完毕。",, "^_^"
WScript.Quit(0)
