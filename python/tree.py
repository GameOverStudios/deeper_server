import curses

def mostrar_arvore(stdscr, arvore, nivel=0, selecionado=0):
  stdscr.clear()
  for i, item in enumerate(arvore):
    if isinstance(item, dict):
      prefixo = "└── " if i == len(arvore) - 1 else "├── "
      chave = list(item.keys())[0]
      stdscr.addstr(nivel, 0, prefixo + chave)
      if i == selecionado:
        stdscr.addstr(nivel, 0, prefixo + chave, curses.A_REVERSE)
      if nivel + 1 < curses.LINES - 1:
        mostrar_arvore(stdscr, list(item.values())[0], nivel + 1, selecionado - i - 1 if selecionado > i else 0) # Chamada recursiva aqui
    else:
      prefixo = "└── " if i == len(arvore) - 1 else "├── "
      stdscr.addstr(nivel, 0, prefixo + item)
      if i == selecionado:
        stdscr.addstr(nivel, 0, prefixo + item, curses.A_REVERSE)
  stdscr.refresh()

def main(stdscr):
  # Carregar a árvore representacional do UnaCMS (substitua pelo código que carrega a árvore)
  arvore = {
    "UnaCMS": {
      "modules": [
        "system",
        "base",
        # ... outros módulos
      ],
      "framework": [
        "BxRouter",
        "BxBaseFunctions",
        # ... outras classes do framework
      ],
      "banco-de-dados": [
        "sys_modules",
        "sys_accounts",
        # ... outras tabelas
      ],
      "templates": [
        "base.html",
        "header.html",
        # ... outros templates
      ]
    }
  }

  selecionado = 0
  while True:
    mostrar_arvore(stdscr, arvore["UnaCMS"], selecionado=selecionado) # Chamada inicial corrigida
    tecla = stdscr.getch()
    if tecla == curses.KEY_DOWN:
      selecionado += 1
    elif tecla == curses.KEY_UP:
      selecionado -= 1
    elif tecla == curses.KEY_ENTER:
      # Ação ao pressionar Enter (ex: mostrar detalhes do item selecionado)
      pass
    elif tecla == ord('q'):
      break

curses.wrapper(main)