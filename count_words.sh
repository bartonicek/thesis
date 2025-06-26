#!/bin/bash
pdftotext ./_book/_main.pdf - | tr -d '.' | wc -w
