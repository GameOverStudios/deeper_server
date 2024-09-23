import os
import argparse

def combinar_arquivos_ex(diretorio_raiz, arquivo_saida_base, count):
  """
  Combina todos os arquivos .ex e .exs em vários arquivos, 
  dividindo-os em grupos de acordo com o parâmetro 'count'.
  Cria apenas arquivos de saída se houver arquivos suficientes.
  """

  arquivos_ex = []
  for dirpath, dirnames, filenames in os.walk(diretorio_raiz):
    for filename in filenames:
      if filename.endswith(".ex") or filename.endswith(".exs"):
        arquivos_ex.append(os.path.join(dirpath, filename))

  total_arquivos = len(arquivos_ex)
  
  # Verifica se há arquivos suficientes para o count
  count = min(count, total_arquivos)

  arquivos_por_grupo = (total_arquivos + count - 1) // count 

  for i in range(count):
    inicio = i * arquivos_por_grupo
    fim = min((i + 1) * arquivos_por_grupo, total_arquivos)
    arquivo_saida = f"{arquivo_saida_base}_{i+1}.ex"

    with open(arquivo_saida, "w") as outfile:
      for j in range(inicio, fim):
        caminho_completo = arquivos_ex[j]
        outfile.write(f"# {caminho_completo}\n\n")
        with open(caminho_completo, "r") as infile:
          outfile.write(infile.read())
        outfile.write("\n\n")

    print(f"Arquivos .ex e .exs combinados em: {arquivo_saida}")

# Configuração do parser de argumentos da linha de comando
parser = argparse.ArgumentParser(description="Combina arquivos .ex e .exs em vários arquivos.")
parser.add_argument("--count", type=int, required=True, help="Número de arquivos de saída a serem criados.")
parser.add_argument("--dir", type=str, required=True, help="Diretório raiz para iniciar a recursão.") 
args = parser.parse_args()

# Diretório raiz para iniciar a busca (obtido do argumento --dir)
diretorio_raiz = args.dir

# Nome base do arquivo de saída
arquivo_saida_base = "arquivos_combinados"

combinar_arquivos_ex(diretorio_raiz, arquivo_saida_base, args.count)