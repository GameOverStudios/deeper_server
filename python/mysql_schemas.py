import mysql.connector
import json
import os
import shutil
from collections import defaultdict

def export_schema(host, user, password, database, output_dir):
    """
    Conecta ao MySQL, extrai o esquema do banco de dados e gera schemas Elixir Phoenix.
    """
    schema = {}
    prefix_counts = defaultdict(int)

    # Apagar diretórios e arquivo .md antes de começar
    if os.path.exists(output_dir):
        shutil.rmtree(output_dir)
    if os.path.exists("UNA_Schemas.md"):
        os.remove("UNA_Schemas.md")

    try:
        mydb = mysql.connector.connect(
            host=host,
            user=user,
            password=password,
            database=database
        )

        mycursor = mydb.cursor()

        # Obter lista de tabelas
        mycursor.execute("SHOW TABLES")
        tables = [table[0] for table in mycursor]

        # Contar prefixos para determinar se cria subdiretórios
        for table in tables:
            parts = table.split("_")
            if len(parts) > 1:
                prefix_counts[parts[0]] += 1

        for table in tables:
            table_data = {}
            print(table)

            # Obter informações da tabela
            mycursor.execute(f"DESCRIBE {table}")
            columns = mycursor.fetchall()

            # Colunas
            table_data['columns'] = []
            for column in columns:
                table_data['columns'].append({
                    'name': column[0].strip(),
                    'type': column[1].strip(),
                    'null': column[2].strip(),
                    'key': column[3].strip(),
                    'default': column[4],
                    'extra': column[5].strip()
                })

            # Chaves estrangeiras
            mycursor.execute(
                f"SELECT TABLE_NAME,COLUMN_NAME,CONSTRAINT_NAME, REFERENCED_TABLE_NAME,REFERENCED_COLUMN_NAME FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA = '{database}' AND TABLE_NAME = '{table}' AND REFERENCED_TABLE_NAME IS NOT NULL")
            foreign_keys = mycursor.fetchall()
            table_data['foreign_keys'] = []
            if foreign_keys:
                for fk in foreign_keys:
                    table_data['foreign_keys'].append({
                        'column': fk[1].strip(),
                        'constraint': fk[2].strip(),
                        'references': f"{fk[3]}.{fk[4]}"
                    })

            # Índices
            mycursor.execute(f"SHOW INDEX FROM {table}")
            indexes = mycursor.fetchall()
            table_data['indexes'] = []
            if indexes:
                for index in indexes:
                    table_data['indexes'].append({
                        'name': index[2],
                        'column': index[4],
                        'unique': index[1]
                    })

            schema[table] = table_data

            # Gerar schema Elixir
            generate_elixir_schema(table, table_data, output_dir, prefix_counts)

    except mysql.connector.Error as err:
        print(f"Erro: {err}")

    finally:
        if mydb.is_connected():
            mycursor.close()
            mydb.close()


def generate_elixir_schema(table_name, table_data, output_dir, prefix_counts):
    """
    Gera o schema Elixir Phoenix para uma tabela, com suporte a agrupamento de tabelas.
    """
    # Definir nome do módulo com base no prefixo da tabela
    if table_name.startswith("bx_"):
        module_prefix = "DeeperServer.CMS.Social."
    elif table_name.startswith("sys_"):
        module_prefix = "DeeperServer.CMS.System."
    else:
        module_prefix = ""  # Sem prefixo para outras tabelas

    schema_name = module_prefix + "_".join(
        word.capitalize() for word in table_name.replace("bx_", "").replace("sys_", "").split("_"))

    # Criar diretório para o schema, se necessário
    if table_name.find('bx_') > -1:
        output_dir = output_dir + '/cms_social/'
    else:
        output_dir = output_dir + '/cms_core/'

    # Criar subdiretórios com base nos nomes repetidos e contagem de prefixos
    parts = table_name.replace('bx_', '').replace('sys_', '').split("_")

    # Lógica para criar subdiretórios
    if len(parts) > 1 and prefix_counts[parts[0]] > 1:  # Cria subdiretório se o prefixo tiver mais de um arquivo
        prefix = os.path.join(parts[0], parts[1])
    else:
        prefix = parts[0]

    schema_dir = os.path.join(output_dir, prefix)
    os.makedirs(schema_dir, exist_ok=True)

    # Gerar código do schema
    schema_content = f"""defmodule {schema_name} do
  use Ecto.Schema
  import Ecto.Changeset

  schema "{table_name.replace('bx_', '').replace('sys_', '')}" do\n"""

    primary_key_defined = False  # Flag para verificar se a chave primária foi definida

    for column in table_data['columns']:
        # Ajustar nome do campo :id
        column_name = column['name']
        if column_name == 'id':
            table_parts = table_name.split('_')
            last_part = table_parts[-1]
            if last_part.endswith('s'):
                last_part = last_part[:-1]  # Remove o "s" final
            column_name = last_part + '_id'

        # Converter tipo de dado MySQL para tipo Ecto
        ecto_type = map_mysql_to_ecto_type(column['type'])
        schema_content += f"    field :{column_name}, :{ecto_type}"

        if column['key'] == 'PRI' and not primary_key_defined:
            schema_content += ", primary_key: true"  # Removido null: false da chave primária
            primary_key_defined = True
        elif column['null'] == 'NO' and column['key'] != 'PRI':  # Adicionado a condição column['key'] != 'PRI'
            schema_content += ", required: true"  # Substituiu null: false por required: true

        # Tratar valores padrão para tipos booleanos
        if column['default'] is not None and column['default'] != '':
            if ecto_type == "boolean":
                schema_content += f", default: {column['default'] == '1'}"  # Converte '1' para True e outros valores para False
            else:
                if column['default'].isdigit():
                    schema_content += f", default: {column['default']}"
                else:
                    schema_content += f', default: "{column["default"]}"'

        schema_content += "\n"

    for fk in table_data['foreign_keys']:
        # Converter nome da tabela referenciada para formato CamelCase com "_" e prefixo do módulo
        ref_table_name = fk['references'].split(".")[0]
        if ref_table_name.startswith("bx_"):
            ref_module_prefix = "DeeperServer.CMS.Social."
        elif ref_table_name.startswith("sys_"):
            ref_module_prefix = "DeeperServer.CMS.System."
        else:
            ref_module_prefix = ""

        ref_schema_name = ref_module_prefix + "_".join(
            word.capitalize() for word in ref_table_name.replace("bx_", "").replace("sys_", "").split("_"))
        schema_content += f"    belongs_to : {fk['references'].split('.')[0].replace('bx_', '').replace('sys_', '')}, {ref_schema_name}\n"

     # Agrupamento de comentários
    if table_name.endswith("_cmts"):
        # Referenciar a tabela genérica sys_cmts
        schema_content += f"""
    belongs_to :system_cmts, DeeperServer.CMS.System.Cmts
    has_many :system_cmts_images, DeeperServer.CMS.System.CmtsImages

    @doc false
    def changeset(struct, params"""  

        # Adicionar campos ao cast
        fields_for_cast = [f":{column_name}" for column in table_data['columns'] if
                          column['key'] != 'PRI' and column_name not in ['cmt_id', 'cmt_pinned']] # Usando column_name aqui
        schema_content += ", ".join(fields_for_cast)

        schema_content += """])
      |> validate_required(["""

        # Adicionar campos obrigatórios ao validate_required
        required_fields = [f":{column_name}" for column in table_data['columns'] if
                          column['null'] == 'NO' and column['key'] != 'PRI' and column_name not in
                          ['cmt_id', 'cmt_pinned']] # Usando column_name aqui
        schema_content += ", ".join(required_fields)

        schema_content += """])
    end
  end
"""
    else:
        # Gerar changeset com campos básicos - você precisará customizar isso para cada schema
        schema_content += """
    timestamps()
  end

  @doc false
  def changeset(struct, params"""

        # Adicionar campos ao cast
        fields_for_cast = [f":{column_name}" for column in table_data['columns'] if column['key'] != 'PRI']

        # Adicionar '\\' apenas se não houver parâmetros
        if not fields_for_cast:
            schema_content += " \\ %{}"

        schema_content += ") do\n    struct\n    |> cast(params, ["

        schema_content += ", ".join(fields_for_cast)

        schema_content += """])
    |> validate_required(["""

        # Adicionar campos obrigatórios ao validate_required
        required_fields = [f":{column_name}" for column in table_data['columns'] if
                          column['null'] == 'NO' and column['key'] != 'PRI']
        schema_content += ", ".join(required_fields)

        schema_content += """])
  end
end
"""

    # Salvar schema em arquivo
    file_name = "_".join(word.lower() for word in table_name.replace("bx_", "").replace("sys_", "").split("_")) + ".ex"
    schema_file = os.path.join(schema_dir, file_name)
    with open(schema_file, "w") as f:
        f.write(schema_content)

    schema_file = os.path.join(".", f"UNA_Schemas.md")
    with open(schema_file, "a") as f:
        f.write('\r\n' + schema_content)


def map_mysql_to_ecto_type(mysql_type):
    """
    Mapeia tipos de dados MySQL para tipos Ecto.
    """
    if "int" in mysql_type:
        return "integer"
    elif "varchar" in mysql_type or "char" in mysql_type:
        return "string"
    elif "text" in mysql_type:
        return "text"
    elif "datetime" in mysql_type:
        return "datetime"
    elif "date" in mysql_type:
        return "date"
    elif "tinyint(1)" in mysql_type:
        return "boolean"
    # Adicione mais mapeamentos conforme necessário
    else:
        return "string"  # Valor padrão para tipos não mapeados


# Configurações de conexão
host = "localhost"
user = "root"
password = ""
database = "una"
output_dir = "lib/deeper_server/cms"

# Exportar o esquema e gerar schemas Elixir
export_schema(host, user, password, database, output_dir)

print(f"Schemas Elixir Phoenix gerados em {output_dir}")