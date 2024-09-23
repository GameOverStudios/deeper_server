' Cria um objeto InputBox para obter a mensagem de commit
strMensagem = InputBox("Digite a mensagem de commit:", "Git Commit")

' Verifica se o usuário clicou em Cancelar ou deixou a caixa de texto vazia
If strMensagem = "" Then
  WScript.Quit
End If

' Cria um objeto Shell
Set objShell = CreateObject("WScript.Shell")

' Define o diretório de trabalho (opcional)
' objShell.CurrentDirectory = "C:\caminho\para\o\repositorio"

' Função para executar um comando e capturar o output
Function ExecutarComando(strComando)
  Set objExec = objShell.Exec(strComando)
  Do While objExec.Status = 0
    WScript.Sleep 2000
  Loop
  ExecutarComando = objExec.StdOut.ReadAll
End Function

' String para armazenar o output de todos os comandos
strOutputTotal = ""

' Executa os comandos Git e adiciona o output à string
strOutputTotal = "------------------------------------------------------------------------------------------------------------------------------------------" & strOutputTotal &  vbCrLf & ExecutarComando("git add .") & vbCrLf & vbCrLf
strOutputTotal = strOutputTotal &  vbCrLf & ExecutarComando("git commit -m """ & strMensagem & """") & vbCrLf & vbCrLf
strOutputTotal = strOutputTotal & vbCrLf & ExecutarComando("git push") & vbCrLf & vbCrLf


' Exibe o output total de todos os comandos
MsgBox strOutputTotal, vbInformation

' Limpa o objeto Shell
Set objShell = Nothing