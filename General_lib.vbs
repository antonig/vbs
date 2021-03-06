public ows       : Set oWs = CreateObject("WScript.Shell")
public fso       : Set fso = CreateObject("Scripting.FileSystemObject")
'--------------------------------------------------------------
'to have this lib included include this sub in your main file and call it from the first lines with the name of this file
'Sub includeFile(fSpec)
'    executeGlobal CreateObject("Scripting.FileSystemObject").openTextFile(fSpec).readAll()
'End Sub
'---------------------------------------------------------
'Abre selector de archivos de windows, usa mshta 
function selecfile
 if Wscript.Arguments.count=1 then
  if myfso.Fileexists(wscript.arguments(0)) then
    Selecfile=Wscript.arguments(0):exit function
 end if
 end if
 dim oexec
 Set oExec=ows.Exec("mshta.exe ""about:<input type=file id=FILE><script>FILE.click();"&_
   "new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1).WriteLine(FILE.value);"&_
   "close();resizeTo(0,0);</script>""")
 Selecfile = oExec.StdOut.ReadLine

end function
'-----------------------------------------------------------------
function getxltable32(path,query)
'devuelve recordset desconectado de tabla excel o csv
'si path incluye nombre archivo xls query debe tener nombre_hoja como nombre tabla
'si path no incluye nombre archivo query debe tener nombre_archivo.csv como nombre tabla

dim oConncsv:Set oRsCsv = CreateObject("ADODB.Connection")
dim orscsv:Set oRsCsv = CreateObject("ADODB.Recordset")
dim connstring 
Const adOpenStatic = 3
Const adLockOptimistic = 3
Const adCmdText = &H0001	
Const provi="Microsoft.Jet.OLEDB.4.0"
if lcase(right(path,3))="xls" then
    connstring="Provider=" & provi   &";" & _
       "Data Source=""" & path & _
       """; Extended Properties=""Excel 8.0;HDR=Yes;"";" 
else
    connstring="Provider=" & provi   &";" & _
      "Data Source=""" & path  & """;" & _
      "Extended Properties=""text;HDR=YES;FMT=Delimited"""
end if
	wscript.echo connstring
  on error resume next
   oConnCsv.Open connstring
    if err then terminar "No puede conectarse a CSV " & path
     wscript.echo query
   oRsCsv.Open query,oConnCsv, adOpenStatic, adLockOptimistic, adCmdText
   if err then terminar "No puede hacerse consulta CSV " & query
  on error goto 0
   wscript.echo "consulta efectuada. registros: "  & oRsCsv.RecordCount
   oRsCsv.Activeconnection=nothing  
   set getxltable32=orscsv
   set oConnCsv=Nothing
   set oRsCsv=Nothing
 end function
 '-------------------------------------------------
function view_rs(r, a ) 
dim s,i,t,l,c,t1
redim l(r.recordcount+1)
'r es un recordset obtenido de consulta
'a array que alterna numeros de columna (base 0) y espacios(negativo alinea derecha)
'si alineacion derecha tiene decimal, se usa Formatnumber con tantos decimales como indican las decimas
   with r.Fields
    s=""
    for i=0 to ubound(a) step 2
      t=a(i+1)
      on error resume next 
      if t<0 then  
        S= s & right(space(-t) & .Item(a(i)).name & " ", -t )
        if err then terminar "campo """& a(i) & """ solicitado no existe"
      else
        S= s & left( .Item(a(i)).name & space(t) , t-1)&" "
        if err then terminar "campo """& a(i) & """ solicitado no existe"
      end if        
      on error goto 0
    next
    l(0)= s
    'wscript.echo s
    c=1
    r.MoveFirst 
    Do Until r.EOF
      s="" 
      for i=0 to ubound(a) step 2
        t=a(i+1)
 
        
        if t<0 then 
          if t<>fix(t) then
            t1=10* abs(t-fix(t)):t=fix(t) 
            if isempty (.Item(a(i))) then
               s=s & space(-t)
            else
                S= s & right(space(-t) & formatnumber(.Item(a(i)),t1,0,0,0) & " ",-t)
            end if
            
          else   
            S= s & right(space(-t) & .Item(a(i)) & " ",-t)
          end if  
        else
          S= s & left( r.Fields(a(i)) & space(t) ,t-1)&" "
        end if  
      next  
      l(c)=s
      r.MoveNext:c=c+1
    Loop
    end with
    view_rs=join(l,vbcrlf)
end function
'----------------------------------------------------------------------
function scriptpath()
  'get the path of this script 
  scriptpath = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
end function	
'-----------------------------------------------------------------------

Function LoadStringFromFile(filename,sp,utf)
    'lee texto de archivo, si se especifica p devuelve array cortado en separadores
    'filename nombre archivo si no se da path se busca en carpeta del script
    'sp       si es "" se devuelve string, si no se devuelve array usando split
    'utf      si es 1 se usa charset utf-8 si 0 se usa ascii 
    dim s
    if instr(filename,"\") then filename=scriptpath & filename 
    With CreateObject("ADODB.Stream")
     .Open
     if utf then .CharSet = "utf-8"
     .loadfromfile filename
     s= .readtext
     .Close
    end with
    if len(sp) then 
       LoadStringFromFile= split(s,sp)
    else
       LoadStringFromFile= s
    end if
End Function


'-----------------------------------------------
sub blocdenotas( byref a,cnt,nom,sep,utf)
'escribe texto ascii o utf-8 a archivo nom y abre bloc de notas ara visualizarlo
's   cadena texto o array valores
'cnt longitud array
'nom nombre archivo si "" se crea nombre.extension, si ".xxx" se usa extension
'sep si s es array, cadena a usar como separador, si s es cadena se ignora
'utf 1 si Charset v a ser utf8, 0 si ascii
 if isarray(a) then 
    redim preserve a(cnt)
    s=join(a,sep)
    erase a    
 else 
   s=a
 end if   
 if nom="" then 
    nom=fso.gettempname
 elseif left(nom,1)="." then 
    nom=replace(fso.gettempname,".tmp",nom)
 end if
 With CreateObject("ADODB.Stream")
     .Open
     if utf then .CharSet = "utf-8"   
     .WriteText s
     .SaveToFile nom, 2
 End With
 ows.run "notepad " & nom,,0
end sub


'--------------------------------------------------------------------
'ASEGURAR HOST CSCRIPT O WSCRIPT Y 32 BITS
'------------------------------------------------------------------
'Asegura host restarts your script with the corrent settings to ensure it runs 
'with the correct version of the vbs engine (console/windows or 32-64 bits)

function EsWin64   'devuelve 1 si es Windows 64 bits
    EsWin64= (GetObject("winmgmts:root\cimv2:Win32_Processor='cpu0'").AddressWidth = 64 )
end function

function nomhost (mode) ' mode es cmd o win
   if ucase(mode)="CMD" then nomhost= "CSCRIPT.EXE" else nomhost= "WSCRIPT.EXE" 
end function

function eshost(mode)  ' mode es cmd o win
     eshost= (instrrev(ucase(WScript.FullName),nomhost(mode))<>0)
end function

function esbits(bits) 'bits es "32" (forzar 32bits) o ""(los bits que tenga el S.O.) 
    esbits=(instr (ucase(WScript.FullName),nomdir(bits))<>0)
end function

function nomdir(bits) 'devuelve carpeta Sistema para Win32 o Win64
     if bits=32 and eswin64 then nomdir="\SYSWOW64\" else nomdir="\SYSTEM32\"
end function

sub AseguraHost(mode,bits) 
' mode "cmd" o "win"  
' bits "32" o ""(indiferente)

  Dim oProcEnv : Set oProcEnv = oWs.Environment("Process") 
  If (EsWin64 and not esbits(bits)) or not eshost(mode) Then
    Dim sArg, Arg
    If Not WScript.Arguments.Count = 0 Then
      For Each Arg In Wscript.Arguments 
        sArg = sArg & " " & """" & Arg & """"
      Next
    end if 
    Dim sCmd : sCmd = """" &  oProcEnv("windir") & nomdir(bits) & nomhost(mode) & """ " & """" & _
      WScript.ScriptFullName & """ " & sarg
    oWs.Run sCmd
    WScript.Quit
  End If
end sub

'------------------------------------------------------
sub isservicerunning (servicename)
'devuelve true si el servicio servicename se está ejecutando
dim flag
'Set wmi = GetObject("winmgmts://./root/cimv2")
on error resume next
flag = (GetObject("winmgmts://./root/cimv2").Get("Win32_Service.Name='" & serviceName & "'").Started)
if err then terminaerror err, "isservicerunning"
on error goto 0
if flag=0 then terminaerror 101, "isservicerunning"
end sub
'------------------------------------

'--------------------------------------------------------

