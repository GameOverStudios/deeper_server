defmodule ModuleInspector do
    @output_dir "output_modules"
  
    def inspect_module(module) do
      # Cria um diretório para o módulo inspecionado
      module_name = Atom.to_string(module)
      module_dir = Path.join(@output_dir, module_name)
      File.mkdir_p!(module_dir)
  
      # Inspeciona tipos e salva em um único arquivo
      inspect_types(module, module_dir)
  
      # Inspeciona funções
      inspect_functions(module, module_dir)
    end
  
    defp inspect_types(module, module_dir) do
      case Code.Typespec.fetch_types(module) do
        {:ok, types} ->
          # Cria uma lista para acumular as especificações
          types_specs = Enum.map(types, fn {type_name, spec} ->
            # Tenta serializar a especificação para string usando inspect
            string_spec = inspect(spec)
  
            "#{Atom.to_string(type_name)}: #{string_spec}"
          end)
  
          # Cria um arquivo para todos os tipos
          file_name = Path.join(module_dir, "types.txt")
          File.write!(file_name, Enum.join(types_specs, "\n"))
  
        _ ->
          IO.puts("Não foi possível obter tipos para o módulo #{module}")
      end
    end
  
    defp inspect_functions(module, module_dir) do
      functions = module.module_info(:exports)
  
      Enum.each(functions, fn {name, arity} ->
        # Captura a documentação da função usando IEx.Introspection.h
        doc_text = get_function_doc(module, name, arity)
  
        # Salva a documentação no arquivo
        file_name = Path.join(module_dir, "func_#{Atom.to_string(name)}_#{arity}.txt")
        File.write!(file_name, doc_text)
      end)
    end
  
    # Função auxiliar para obter a documentação de uma função específica
    defp get_function_doc(module, name, arity) do
      # Captura a saída do IEx.Introspection.h
      {:ok, output} = capture_io(fn ->
        IEx.Introspection.h({module, name, arity})
      end)
  
      # Remove caracteres ANSI
      remove_ansi(output)
    end
  
    # Remove caracteres ANSI
    defp remove_ansi(text) do
      Regex.replace(~r/\e\[\d+m/, text, "")
    end
  
    # Função auxiliar para capturar a saída no IEx
    defp capture_io(fun) do
      {:ok, pid} = StringIO.open("")
      old_group_leader = Process.group_leader()
      Process.group_leader(self(), pid)
      try do
        fun.()
        {:ok, StringIO.contents(pid) |> elem(1)}
      after
        Process.group_leader(self(), old_group_leader)
      end
    end
  end
  
  # Uso no IEx:
  # ModuleInspector.inspect_module(:gen_tcp)
  