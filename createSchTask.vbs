Dim Fso, Ws, ext, shpg, cwd, fp, cmdstr, rungap

' Author: tyasky

Set Fso = CreateObject("Scripting.FileSystemObject")
Set Ws = WScript.CreateObject("Wscript.Shell")

ext= Ws.RegRead("HKEY_CLASSES_ROOT\.sh\")
shpg = Split(Ws.RegRead("HKEY_CLASSES_ROOT\" & ext & "\shell\open\command\"), """")(1)
shpg = Fso.GetFile(shpg).ShortPath

cwd = Fso.GetParentFolderName(WScript.ScriptFullName)
fp = Fso.BuildPath(cwd, "aliddns.sh")
fp = Fso.GetFile(fp).ShortPath

cmdstr = shpg & " --hide " & fp

' 启用事件日志
Ws.Run "cmd /c wevtutil sl Microsoft-Windows-Dhcpv6-Client/Operational /e:true", 0

' 创建 51050 事件触发的计划任务
Ws.Run "cmd /c SCHTASKS /Create /TN aliddns /SC ONEVENT /EC Microsoft-Windows-Dhcpv6-Client/Operational /MO ""*[System[EventID=51050]]"" /TR  """ & cmdstr & """", 0

MsgBox "脚本运行完毕。",, "^_^"
WScript.Quit(0)
