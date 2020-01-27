
import os, strutils

const
  extensions = [".js", ".html", ".css", ".gif", ".png"]

proc exec(cmd: string) =
  if execShellCmd(cmd) != 0:
    echo "failed ", cmd

for f in walkDirRec(paramStr(1)):
  for x in extensions:
    if f.endsWith(x):
      exec "git add " & f
