---
title: "The Fabric of Interactive Visualization"
subtitle: "From the Algebra of Graphics, Statistics, and Interaction to Practical Implementation"
author: "Adam Bartonicek"
site: bookdown::bookdown_site
documentclass: book
always_allow_html: true
output:
  bookdown::gitbook:
    css: styles.css
  bookdown::pdf_document2:
    latex_engine: xelatex
  bookdown::pdf_book:
    latex_engine: xelatex
bibliography: [references.bib]
biblio-style: "apalike"
link-citations: true
editor_options: 
  chunk_output_type: console
header-includes:
  - \usepackage{tikz-cd}
---

# Abstract 

Interactive data visualization has become a staple of modern data presentation. Yet, despite its growing popularity, there still exists many unresolved issues which make the process of producing rich interactive data visualizations difficult. Chief among these is the problem of data pipelines: how do we design a framework for turning raw data into summary statistics that can then be visualized, efficiently, on demand, and in a visually coherent way? Despite seeming like a straightforward task, there are in fact many subtle problems that arise when designing such a pipeline, and some of these may require a dramatic shift in perspective. In this thesis, I argue that, in order to design coherent generic interactive data visualization systems, we need to ground our thinking in concepts from some fairly abstract areas of mathematics including category theory and abstract algebra. By leveraging these algebraic concepts, we may be able to build more flexible and expressive interactive data visualization systems.





\newcommand\then{⨾}

