CRESTC := crestc
RUN_CREST := run_crest
TARGET := grep
SRC := grep.c

# CREST OPTION
CREST_MAX_TC := 10000
# -dfs | -random | -uniform | -cfg
CREST_STRATEGY := -dfs

$(TARGET): $(SRC)
	$(CRESTC) $<

run: $(TARGET)
	$(RUN_CREST) $(abspath $<) $(CREST_MAX_TC) $(CREST_STRATEGY)

clean:
	-rm branches cfg cfg_func_map cfg_branches coverage funcount grep.cil.* grep.i idcount input stmtcount szd_execution $(TARGET) $(SRC:.c=.o)	

