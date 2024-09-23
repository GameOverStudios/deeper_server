import os
import re
import shutil
import sys
import argparse
import filecmp
import time

def apagar_arquivos_e_pastas(diretorio):
    """
    Apaga todos os arquivos e pastas dentro de um diretório.

    Args:
        diretorio: Caminho para o diretório a ser limpo.
    """
    if os.path.exists(diretorio):
        for filename in os.listdir(diretorio):
            caminho_completo = os.path.join(diretorio, filename)
            if os.path.isfile(caminho_completo):
                os.remove(caminho_completo)
                print(f"Arquivo '{filename}' apagado.")
            elif os.path.isdir(caminho_completo):
                shutil.rmtree(caminho_completo)
                print(f"Pasta '{filename}' apagada.")
    else:
        os.makedirs(diretorio)

def apagar_arquivos_old(diretorio):
    """
    Apaga todos os arquivos com extensão .old dentro de um diretório e seus subdiretórios.

    Args:
        diretorio: Caminho para o diretório a ser limpo.
    """
    for root, _, files in os.walk(diretorio):
        for file in files:
            if file.endswith(".old"):
                file_path = os.path.join(root, file)
                os.remove(file_path)
                print(f"Arquivo .old apagado: {file_path}") 

def create_file(file_path, routes_file, history_file):
    """
    Processa um arquivo .md e gera arquivos .ex correspondentes para cada controlador Elixir encontrado.
    Também adiciona as rotas ao arquivo routes.ex.
    """
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()

    # Substitui \" por " no conteúdo (opcional)
    content = content.replace('\\"', '"') 

    # Extrai controladores Elixir usando blocos de código
    controller_pattern = re.compile(r'```elixir\n(.*?)\n```', re.DOTALL)
    controllers = controller_pattern.findall(content)

    # Encontra a linha que contém "**Rotas:**"
    rotas_index = content.find("**Rotas:**")

    if rotas_index != -1:
        # Extrai o código Elixir após a linha "**Rotas:**"
        routes_code = content[rotas_index + len("**Rotas:**"):]

        # Remove aspas duplas extras 
        routes_code = routes_code.replace('\\"', '"')

        # Extrai blocos de código Elixir dentro do código de rotas
        routes_pattern = re.compile(r'```elixir\n(.*?)\n```', re.DOTALL)
        routes_blocks = routes_pattern.findall(routes_code)

        # Adiciona as rotas ao arquivo routes.ex
        for routes_code_block in routes_blocks:
            with open(routes_file, 'a', encoding='utf-8') as routes_file_obj:
                routes_file_obj.write(routes_code_block + '\n')
            print(f"Rotas adicionadas ao arquivo: {routes_file} (de {file_path})")

    for controller_code in controllers:
        # Substitui \" por " no código do controlador (opcional)
        controller_code = controller_code.replace('\\"', '"')
        controller_code = controller_code.replace('\\"', '"') 

        # Extrai informações do controlador do código
        module_pattern = re.compile(r'defmodule (.*?) do')
        module_match = module_pattern.search(controller_code)

        if module_match:
            module_name = module_match.group(1)
            parts = module_name.split('.')
            # Adiciona AIGen ao caminho do diretório
            if 'Controller' in parts[-1]:
                directory = os.path.join("AIGen", "Controller", *parts[:-1])  
            else:
                directory = os.path.join("AIGen", *parts[:-1])
            file_name = f"{parts[-1]}.ex"

            # Cria o diretório se não existir
            if not os.path.exists(directory):
                os.makedirs(directory)

            # Caminho do arquivo de saída
            output_file_path = os.path.join(directory, file_name)

             # Verifica se o arquivo já existe 
            if os.path.exists(output_file_path): 
                # Renomeia o arquivo existente para _old com um contador
                base_name, ext = os.path.splitext(file_name)
                counter = 1
                old_file_name = f"{base_name}.old"
                old_file_path = os.path.join(directory, old_file_name)

                while os.path.exists(old_file_path):
                    old_file_name = f"{base_name}.old_{counter}"
                    old_file_path = os.path.join(directory, old_file_name)
                    counter += 1

                os.rename(output_file_path, old_file_path)
                print(f"Arquivo existente renomeado para: {old_file_path}")

            # Cria/sobrescreve o arquivo .ex com o conteúdo do controlador
            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write(controller_code)

            print(f"Arquivo gerado: {output_file_path}")

def main():
    parser = argparse.ArgumentParser(description="Processa arquivos .md e gera arquivos .ex.")
    parser.add_argument("--new", action="store_true", help="Apaga todos os arquivos e pastas no diretório de saída antes de gerar novos arquivos.")
    parser.add_argument("--history", default="python\history v3.0.json", help="Nome do arquivo history.json (padrão: history v3.0.json).")
    args = parser.parse_args()

    
    aigen_path = os.path.join('.', 'AIGen') # Define o caminho para a pasta AIGen
    tasks_path = os.path.join(aigen_path, 'Tasks') # Define o caminho para a pasta Tasks dentro de AIGen
    history_file = args.history  # Nome do arquivo history.json
    routes_file = os.path.join(aigen_path, 'routes.ex')

    script_dir = os.path.dirname(os.path.abspath(__file__))
    history_path = os.path.join(script_dir, history_file)

    if args.new:
        apagar_arquivos_e_pastas(aigen_path) # Apaga tudo dentro de AIGen

    # Cria as pastas AIGen e Tasks se não existirem
    if not os.path.exists(aigen_path):
        os.makedirs(aigen_path)
    if not os.path.exists(tasks_path):
        os.makedirs(tasks_path)
    
    # Limpa o arquivo de rotas se já existir (apenas uma vez no início)
    if os.path.exists(routes_file) and args.new: 
        os.remove(routes_file)

    strings_encontradas = []
    with open(history_path, 'r', encoding='utf-8') as f:
        linhas = f.readlines()
        for i in range(len(linhas)):
            if linhas[i].strip() == '"role": "model",':
                if i + 1 < len(linhas) and linhas[i + 1].strip() == '"parts": [':
                    if i + 2 < len(linhas) and linhas[i + 2].strip().startswith('"') and linhas[i + 2].strip().endswith('",'):
                        
                        #Linha
                        string = linhas[i + 2].strip()[1:-2].replace(':text',':string')
                        strings_encontradas.append(string)
                        nome_arquivo = f"{i+1}.md"
                        with open(os.path.join(tasks_path, nome_arquivo), 'w', encoding='utf-8') as f: # Salva os arquivos .md em AIGen/Tasks
                            f.write(string.replace("\\n", "\n"))
                            print(i)

    # Apaga os arquivos .old na pasta AIGen
    apagar_arquivos_old(aigen_path) 

    # Obtemos todos os arquivos .md no diretório especificado
    if os.path.exists(tasks_path):
        for file_name in os.listdir(tasks_path):
            if file_name.endswith('.md'):
                file_path = os.path.join(tasks_path, file_name)
                create_file(file_path, routes_file, history_file) 

if __name__ == "__main__":
    main()