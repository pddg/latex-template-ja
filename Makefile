MAIN_SRC=main
USE_DOCKER?=yes
DOCKER_IMAGE=pddg/latex:2.0.0

# TeX sources
STY_SRCS=$(wildcard ./*.sty)
BIB_SRCS=$(wildcard ./*.bst) $(wildcard ./*.bib)
TEX_SRCS=$(wildcard ./*.tex) $(wildcard */*.tex)

# Figures
FIG_DIR=figures
FIG_PNG=$(wildcard $(FIG_DIR)/*.png)
FIG_JPG=$(wildcard $(FIG_DIR)/*.jpg) $(wildcard $(FIG_DIR)/*.JPG) $(wildcard $(FIG_DIR)/*.jpeg)
FIG_EPS=$(wildcard $(FIG_DIR)/*.eps)
FIG_PDF=$(wildcard $(FIG_DIR)/*.pdf)
FIGS=$(FIG_PNG) $(FIG_JPG) $(FIG_EPS) $(FIG_PDF)

ifeq "$(OS)" "Windows_NT"
	UIDOPT=
	RMCMD=cmd.exe /C del
else
	UNAME=$(shell uname)
	RMCMD=rm -f
	ifeq ($(UNAME), Linux)
		UID=$(shell id -u)
		GID=$(shell id -g)
		UIDOPT=-u $(UID):$(GID)
	else
		UIDOPT=
	endif
endif

DOCKER_CMD=docker run --rm $(UIDOPT) -v $(CURDIR):/workdir $(DOCKER_IMAGE)

ifeq "$(USE_DOCKER)" "yes"
	LATEXMK_CMD=$(DOCKER_CMD) latexmk
	WATCH_OPTION=-pvc -view=none
else
	LATEXMK_CMD=latexmk
	WATCH_OPTION=-pvc
endif

.DEFAULT_GOAL := pdf

all: clean pdf

pdf: $(MAIN_SRC).pdf

$(MAIN_SRC).pdf: $(TEX_SRCS) $(STY_SRCS) $(BIB_SRCS) $(FIGS)
	$(LATEXMK_CMD)

target=$(MAIN_SRC).tex
watch:
	$(LATEXMK_CMD) $(WATCH_OPTION) $(target)

clean:
	$(LATEXMK_CMD) -C

.latexmkrc:
	$(DOCKER_CMD) cp /.latexmkrc ./

latexmkrc: .latexmkrc

branch=wip
draft:
	git checkout -b $(branch)
	git commit -m "WIP" --allow-empty
	git push -u origin $(branch)
	hub compare

.PHONY: all pdf clean watch docker docker-watch latexmkrc draft
