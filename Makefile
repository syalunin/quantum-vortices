
.PHONY: all clean

SRC_DIR = src

all:
	$(MAKE) -C $(SRC_DIR)

clean:
	$(MAKE) -C $(SRC_DIR) clean
