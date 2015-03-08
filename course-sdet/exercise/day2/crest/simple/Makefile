main: main.c
	crestc $<

.PHONY: run clean
run: main
	run_crest $(abspath main) 1000 -dfs

clean:
	-@rm szd_execution branches input coverage main main.o main.cil.* main.i idcount funcount stmtcount cfg cfg_func_map cfg_branches

