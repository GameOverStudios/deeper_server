import os

def juntar_arquivos_md(diretorio, arquivo_saida):
  """
  Junta todos os arquivos .md em um diretório em um único arquivo de saída.

  Args:
      diretorio: Caminho para o diretório onde os arquivos .md estão localizados.
      arquivo_saida: Nome do arquivo de saída onde o conteúdo será juntado.
  """
  with open(arquivo_saida, "w", encoding="utf-8") as saida:
    for filename in os.listdir(diretorio):
      if filename.endswith(".md"):
        caminho_arquivo = os.path.join(diretorio, filename)
        with open(caminho_arquivo, "r", encoding="utf-8") as entrada:
          conteudo = entrada.read()
          saida.write(conteudo)
          saida.write("\n\n---\n\n")  # Adiciona um separador entre os arquivos

  print(f"Arquivos .md juntados em '{arquivo_saida}'.")

# Diretório onde os arquivos .md estão localizados
diretorio = "tasks"  # Altere para o diretório desejado

# Nome do arquivo de saída
arquivo_saida = "tasks.md"  # Altere para o nome desejado

# Chama a função para juntar os arquivos .md
juntar_arquivos_md(diretorio, arquivo_saida)