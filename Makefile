SHELL := /bin/sh

MAIN_SRC := main
DOCKER_IMAGE=pddg/latex:2.0.0

# TeX sources
STY_SRCS=$(wildcard ./*.sty)
BIB_SRCS=$(wildcard ./*.bst) $(wildcard ./*.bib)
TEX_SRCS=$(wildcard ./*.tex)

# Figures
FIG_DIR=figures
FIG_PNG=$(wildcard $(FIG_DIR)/*.png)
FIG_JPG=$(wildcard $(FIG_DIR)/*.jpg) $(wildcard $(FIG_DIR)/*.JPG)
FIG_EPS=$(wildcard $(FIG_DIR)/*.eps)
FIG_PDF=$(wildcard $(FIG_DIR)/*.pdf)
FIGS=$(FIG_PNG) $(FIG_JPG) $(FIG_EPS) $(FIG_PDF)

ifeq ($(OS), Windows_NT)
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
LATEXMK_CMD=latexmk
WATCH_CMD=$(LATEXMK_CMD) -pvc
PDF_BUILD_CMD=$(LATEXMK_CMD)
.DEFAULT_GOAL := pdf

all: clean pdf

pdf: $(MAIN_SRC).pdf

$(MAIN_SRC).pdf: $(TEX_SRCS) $(STY_SRCS) $(BIB_SRCS) $(FIGS)
	$(PDF_BUILD_CMD)

target=$(MAIN_SRC).tex
watch:
	$(WATCH_CMD) $(target)

clean:
	$(RMCMD) *.dvi *.aux *.toc *.log *.bbl *.blg *~ *.bak *.synctex.gz *.pdf *.fdb_latexmk *.fls

# Override build command to use docker container
docker: PDF_BUILD_CMD=$(DOCKER_CMD) $(LATEXMK_CMD)
docker: $(MAIN_SRC).pdf

docker-all: PDF_BUILD_CMD=$(DOCKER_CMD) $(LATEXMK_CMD)
docker-all: clean $(MAIN_SRC).pdf

docker-watch:
	$(DOCKER_CMD) $(WATCH_CMD) -view=none $(target)

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
