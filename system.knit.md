---
output: html_document
editor_options: 
  chunk_output_type: console
alway_allow_html: true
---



# System description {#system}

This section contains a detailed description of the two software packages developed as part of this doctoral project: ([plotscape](https://github.com/bartonicek/plotscape) and [plotscaper](https://github.com/bartonicek/plotscaper)):

- `plotscape`: Written in TypeScript/JavaScript, provides "low-level" interactive visualization utilities
- `plotscaper`: Written in R, provides a "high-level" wrapper/API for R users 

A couple of general notes. Firstly, the low-level platform (`plotscape`) was written with web technologies (JavaScript, HTML, and CSS). Web technologies were chosen because they provide a simple and portable way to do interactive apps in R, having become the de facto standard thanks to good integration provided by packages such as `htmlwidgets` [@htmlwidgets2021] and Shiny [@sievert2020]. Second, the functionality was split across two packages out of practical concerns; rather than relying on some JS-in-R wrapper library, `plotscape` was implemented as a standalone vanilla TypeScript/JavaScript library, to achieve optimal performance and fine-grained control. `plotscaper` was then developed to provide a user-friendly R wrapper around `plotscape`'s functionalities.  

As of the time of writing, `plotscape` comprises of about 6,400 significant lines of code (SLOC; un-minified, primarily TypeScript but also some CSS, includes tests, etc...), and `plotscaper` contains about 500 SLOC of R code (both counted using [`cloc`](https://github.com/AlDanial/cloc)). The unpacked size of all (minified) files is about 200 kilobytes for `plotscape` and 460 kilobytes for `plotscaper`, which is fairly modest compared to other interactive data visualization alternatives for R^[For instance, the `plotly` package takes up about 7.3 megabytes, which amounts to over 15x difference.]. Both packages have fairly minimal dependencies.

Since the two packages address fairly well-separable concerns - high-level API design vs. low-level interactive visualization utilites - I decided to organize this section accordingly. Specifically, I first discuss general, high-level API concerns alongside `plotscaper` functionality. Then I delve into the low-level implementation details alongside `plotscape`. There are of course cross-cutting concerns and those will be addressed towards ends of the respective sections. However, first, let's briefly review the core requirement of the package(s).

## Core requirements

To re-iterate, from Section \@ref(goals), the core requirements for the high-level API (`plotscaper`) were:

- Facilitate creation and manipulation of interactive figures for data exploration
- Be accessible to a wide range of users with varying levels of experience
- Integrate well with popular tools within the R ecosystem

These overarching goals, explored further in Section \@ref(high-level-api), translated into more requirements:

- Simple and intuitive API for creating and manipulating multi-panel interactive figures (see e.g. Sections \@ref(figure-plot), \@ref(variables-encodings), and \@ref(scene-and-schema))
- Support for interactive features such as generalized linked selection, parameter manipulation and representation switching, and other standard features like zooming, panning, and querying (discussed throughout)
- Two-way communication between figures and interactive R sessions (see Section \@ref(client-server))
- Static embedding capabilities for R Markdown/Quarto documents (see Section \@ref(html-embedding))

To realize these goals, it was necessary to design the low-level platform (`plotscape`) which could support them. The primary purpose of `plotscape` was to provide utilities for the interactive data visualization pipeline:

- Splitting the data into a hierarchy of partitions
- Computing and transforming summary statistics (e.g. stacking, normalizing)
- Mapping these summaries to visual encodings (e.g. x- and y-axis position, width, height, and area)
- Rendering geometric objects and auxiliary graphical elements
- Responding to user input and server requests, propagating any required updates throughout the pipeline (reactivity)

Section \@ref(low-level-implementation) focuses on the concerns surrounding these more fine-grained implementation details. Specifically, it discusses:

- The programming paradigm used in `plotscape` (Section \@ref(programming-paradigm))
- Row vs. column based data representation (Section \@ref(row-column))
- Reactivity (Section \@ref(reactivity))
- Specific components of the system and their relations (Section \@ref(components))

Note that the most granular implementation details of `plotscape` are discussed in Section \@ref(components) (along with concrete code examples), so some readers may find it easier to start with this section.

## High-level API (`plotscaper`) {#high-level-api}

In Section \@ref(goals), I already discussed some broad, theoretical ideas related to the package's functionality. Here, I focus more on the concrete API - what `plotscaper` code looks like, how are the users supposed to understand it, and why was the package designed this way. The goal is to provide a rationale for key design decisions and choices.

### API design {#api-design}

As mentioned in Section \@ref(goals), a primary inspiration for `plotscaper`'s API was the popular R package `ggplot2`. In `ggplot2`, plots are created by chaining together a series of function calls, each adding or modifying a component of an immutable plot schema:


``` r
library(ggplot2)

# Plots are created by chaining a series of function calls
ggplot(mtcars, aes(wt, mpg)) +
  geom_point() +   # The overloaded `+` serves as pipe operator
  scale_x_continuous(limits = c(0, 10))
```


``` r
# The ggplot() call creates an immutable plot schema
plot1 <- ggplot(mtcars, aes(wt, mpg))
names(plot1)
```

```
##  [1] "data"        "layers"      "scales"      "guides"      "mapping"    
##  [6] "theme"       "coordinates" "facet"       "plot_env"    "layout"     
## [11] "labels"
```

``` r
length(plot1$layers)
```

```
## [1] 0
```

``` r
# Adding components such as geoms or scales returns a new schema
plot2 <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
names(plot2)
```

```
##  [1] "data"        "layers"      "scales"      "guides"      "mapping"    
##  [6] "theme"       "coordinates" "facet"       "plot_env"    "layout"     
## [11] "labels"
```

``` r
length(plot2$layers)
```

```
## [1] 1
```

`ggplot2` is well-loved by R users, as evidenced by the package's popularity. However, its API presents certain limitations when building interactive figures. Specifically:

- Its design primarily centers around individual plots. While facetting does make it possible to create multi-panel figures consisting of repeats of the same plot type [see `facet_wrap()` and `facet_grid()`, @wickham2016], creating mixed plot-type multi-panel figures requires the use of external packages such as `gridExtra` [@auguie2017] or `patchwork` [@pedersen2024]. As discussed in Section \@ref(background), in interactive graphics, multi-panel figures are essential and should be considered first-class citizens.
- While the immutable schema model works well for static graphics, in interactive graphics, the ability to modify an already rendered figure via code can be extremely useful. For example directly setting a histogram binwidth to a precise value via a function call offers superior control compared to using an imprecise widget such as a slider.
- Many of the `ggplot2`'s core functions make heavy use of quotation and non-standard evaluation [NSE, @wickham2019]. While this style is fairly popular within the R ecosystem and does offer syntactic conciseness, it also complicates programmatic use [@wickham2019]. For instance, in `ggplot2`, to plot all pairwise combinations of the variables in a dataframe, we cannot simply loop over their names and supply these as arguments to the default `aes` function - instead, we have to parse the names within the dataframe's environment (this is what the specialized `aes_string` function does). Again, in interactive contexts, the ability to easily manipulate figures with code is often highly useful, and this makes NSE a hindrance (more on this later).  
- The package was developed before widespread adoption of the pipe operator [both `%*%` from `magrittr`, @bache2022; and the native R `|>` pipe, @r2024] and its use of the overloaded `+` operator is a noted design flaw [see @wickham2014].

In `plotscaper`, I addressed these issues as follows. First, a function-chaining approach similar to `ggplot2` was adopted, however, with a focus on multi-panel figure composition. Most functions modify the entire figure, however, specialized functions with selectors can also target individual plots (see Sections \@ref(basic-example) and \@ref(figure-plot). Second, to enable mutable figure modification while retaining the benefits of immutability, most functions can operate on both immutable figure schemas and references to live figures, with the operations being applied homomorphically (this will be discussed in Section \@ref(scene-and-schema)). Finally, non-standard evaluation was avoided altogether, and functions can be composed using any valid pipe operator^[Throughout the examples in this thesis, I use the base R `|>` operator, however, the `%>%` operator from the `magrittr` package [@bache2022] would work equally well.]. 

### Basic example {#basic-example}

The code below shows an example of a simple interactive figure created with `plotscaper`. More advanced and realistic applications are shown in Section \@ref(applied-example); this is example is only meant to provide a simple illustration:


``` r
library(plotscaper)

create_schema(mtcars) |>
  add_scatterplot(c("wt", "mpg")) |>
  add_barplot(c("cyl")) |>
  set_scale("plot1", "x", min = 0) |>
  render()
```

\begin{figure}
\includegraphics[width=10.83in]{./figures/plotscaper_example1} \caption{An example of a simple interactive figure in `plotscaper`.}(\#fig:plotscaper-example1)
\end{figure}

We first initialize the figure schema by calling `create_schema` with the input data. Next, we chain a series of `add_*` calls, adding individual plots. Furthermore, we can manipulate attributes of individual plots by using specialized functions. For instance, in the example above, `set_scale` is used to set the lower x-axis limit of the scatterplot to zero. When a schema is provided as the first argument, these functions append immutable instructions to the schema, a process which will be detailed in Section \@ref(scene-and-schema). Finally, call to `render` instantiates the schema, creating an interactive figure. Several aspects of this workflow warrant further explanation which will be provided in the subsequent sections.

#### Figure vs. plot and selectors {#figure-plot}

First, note that, as discussed in Section \@ref(api-design), all `plotscaper` functions take as their first argument the entire figure. This differs from `ggplot2` functions, which typically operate on a single plot (unless facetting is applied). Thus, the primary target of manipulation is the entire figure, rather than a single plot. This design necessitates the use of selectors for targeting individual plots, as seen in the `set_scale` call above. I decided to use a simple string selector for this purpose. While alternative selection strategies, such as overloading the extraction (`$`) operator or using a dedicated selector function were also considered, upon considering the inherent trade-offs, I decided to go with the straightforward method of string selectors. This design choice is open to being revisited in future major releases of the package.

#### Variable names

Second, `plotscaper` also uses simple string vectors to specify data variable names. This means that the function arguments are *not* treated as quoted symbols^[The terminology here is a bit unfortunate, since the *unquoted* string arguments *are* surrounded by quotes.]. For example, we use `add_scatterplot(c("x", "y", "z"))` instead of `add_scatterplot(c(x, y, z))`. While this style requires two extra key strokes for each variable and might feel less familiar to some R users, I believe that its suitability for programmatic use makes it a worthwhile trade-off. For instance, a user of `plotscaper` can easily create an interactive scatterplot matrix (SPLOM) like so:


``` r
column_names <- names(mtcars)[c(1, 3, 4)]
schema <- create_schema(mtcars)

for (i in column_names) {
  for (j in column_names) {
    if (i == j) schema <- add_histogram(schema, c(i))
    else schema <- add_scatterplot(schema, c(i, j))
  }
}

schema |> render()
```

\begin{figure}
\includegraphics[width=10.83in]{./figures/plotscaper-example2} \caption{An example of a programmatically-created scatterplot matrix (SPLOM).}(\#fig:plotscaper-example2)
\end{figure}

While this scatterplot matrix could be also recreated with quotation/NSE using functions like `substitute` from base R [@r2024] or `enquo` from `rlang` [@rlang2024], doing so requires the knowledge of quasiquotation which is part of [advanced R](https://adv-r.hadley.nz/quasiquotation.html#quasiquotation). Many R users may be familiar with calling functions using "naked" variable names, however, actual proficiency with using quotation effectively may be less common. Furthemore, R's NSE is a form of metaprogramming [@wickham2019]. While powerful, over-reliance on metaprogramming is often discouraged in modern developer circles, due to it potential to impact performance, safety, and readability [see e.g. @phung2009; the discussion at @handmadehero2025]. Thus, to promote simplicity and programmatic use, I chose simple string vectors over quoted function arguments in `plotscaper`.

#### Variables and encodings {#variables-encodings}

Third, note that, in `plotscaper`, variable names are *not* meant to map directly to aesthetics such as x- or y-axis position or size. In other words, unlike `ggplot2`, `plotscaper` does not try to establish a direct correspondence between original data variables and the visual encodings/aesthetics. The reason for this is tha, in many common plot types, aesthetics do not actually represent variables found in the original data, but instead ones which have been derived or computed. Take, for instance, the following `ggplot` call:


``` r
ggplot(mtcars, aes(x = mpg)) + 
  geom_histogram()
```


\includegraphics[width=20.83in]{./figures/ggplot-histogram-aes} 

Overtly, it may seem as if the `aes` function maps the `mpg` variable to the x-axis. This would be the case if, for example, `geom_point` had been used, however, with `geom_histogram`, this interpretation is incorrect. Specifically, the x-axis actually represents the left and right edges of the histogram bins, a derived variable not found in the original data. Similarly, the y-axis shows bin counts, another derived variable. Setting custom histogram breaks makes this lack of a direct correspondence even clearer:     


``` r
ggplot(mtcars, aes(x = mpg)) + 
  geom_histogram(breaks = c(10, 15, 35))
```


\includegraphics[width=20.83in]{./figures/ggplot-histogram-aes2} 

Now it is easier to see that what gets mapped to the x-axis is *not* the `mpg` variable. Instead, it is the variable representing the histogram breaks. The `mpg` variable gets mapped to the plot only implicitly, as the summarized counts within the bins (the y-axis variable). Thus, in `ggplot` call, the semantics of `aes(x = mpg, ...)` are fundamentally different in `geom_histogram` as compared to, for example, `geom_scatter`.

While this lack of a direct correspondence between data and aesthetics may seem like a minor detail, it is in fact a fundamental design gap. As discussed in Section \@ref(problems), `ggplot2` is based on the Grammar of Graphics model [@wilkinson2012], which centers around the idea of composing plots out of independent, modular components. The fact that the semantics of `aes` are tied to `geom`s (and `stat`s) means that these classes of `ggplot2` functions are not truly independent. This issue is even further amplified in interactive graphics. For instance, when switching the representation of histogram to spinogram, we use the same underlying data but the aesthetic mappings are completely different. The expression `aes(x = mpg)` would be meaningless in a spinogram, since both the x- and y-axes display binned counts - `mpg` only facilitates binning and is not displayed anywhere in the plot directly. 

So what to do? To be perfectly frank, I have not found a perfect solution. In Section \@ref(problems), I proved that, in the general case involving transformations like stacking, `stats` and `geoms` *cannot* be truly independent. Barring that, the problem with specifying aesthetics in plots like histograms is that, in some sense, we are putting the cart before the horse: ultimately, we want to plot derived variables, so we should specify these in the call to `aes`, however, we do not know what the derived variables will be before we compute them (requiring the knowledge of `stat`s and `geom`s). So perhaps the schema creation process should organized in a different way. As per Section \@ref(problems), we could mirror the data visualization pipeline by structuring the code like:    


``` r
data |> 
  partition(...) |> 
  aggregate(...) |> 
  encode(...) |> 
  render(...)
```

In broad strokes, this is how the data visualization pipeline is implemented in `plotscape` (see Section \@ref(low-level-implementation)). However, this model does have one important downside: it does not lend itself easily to a simple declarative schema like that of `ggplot2`. Despite several attempts, and some partial successes (see Section \@ref(summaries)), on the whole, I have been unsuccessful in developing a comprehensive way to specify such a schema. The difficulties stem from the hierarchical dependencies between the various pipeline stages, as well as the added complexity of integrating reactivity into the pipeline (see also Section \@ref(declarative-schemas)).

This difficulty with declarative schemas is why I opted for the more traditional, nominal style of specifying plots in `plotscaper`(i.e. using functions like `add_scatterplot` or `add_barplot`). While this approach may seem less flexible, I hope I have demonstrated that the underlying limitations are *not* an exclusive to `plotscape`/`plotscaper`, but extend to `ggplot2` and all other GoG-based data visualization systems. I have simply chosen make these limitations more explicit. If a better solution is found, it may be integrated into future releases of the package.

A final point to mention is that it could be argued that one benefit of the `ggplot2` model where partitioning and aggregation logic (`stat`s) is implicitly tied to `geom`s is that it makes it easier to combine several kinds of `geom`s in one plot. For instance, `geom_histogram` can be combined with `geom_rug`, while single-case `geom_points` can be combined with aggregate summaries computed via `stat_summary`. Ignoring the conceptual problem of non-independence discussed above, this approach works fine for static graphics, where performance is not a key concern. However, in interactive graphics, computing a separate set of summaries for each `geom` layer may create unnecessary computational bottlenecks. Therefore, interactive graphics may benefit from sharing aggregated data whenever possible, and this is only possible if the partitioning and aggregation steps of the data visualization pipeline are lifted out of `geom`s. 

### The scene and the schema {#scene-and-schema}

A key part of the `plotscaper` API is the distinction between two classes of objects representing figures: schemas and scenes. Put simply, a schema is an immutable ledger or blueprint, specifying how a figure is created, while a scene is a live, rendered version of the figure which can be directly modified. Both can be manipulated using (largely) the same set of functions, implemented as `S3` methods which dispatch on the underlying class.

As shown before, schema can be created with the `create_schema` function: 




``` r
schema <- create_schema(mtcars) |>
  add_scatterplot(c("wt", "mpg")) |>
  add_barplot(c("cyl"))

schema
```

```
## plotscaper schema:
## add-plot { type: scatter, variables: c("wt", "mpg") }
## add-plot { type: bar, variables: cyl }
```

``` r
str(schema$queue)
```

```
## List of 2
##  $ :List of 2
##   ..$ type: chr "add-plot"
##   ..$ data:List of 3
##   .. ..$ type     : 'scalar' chr "scatter"
##   .. ..$ variables: chr [1:2] "wt" "mpg"
##   .. ..$ id       : 'scalar' chr "896922e9-ce1f-4bb6-99e4-c5648d1b2305"
##  $ :List of 2
##   ..$ type: chr "add-plot"
##   ..$ data:List of 3
##   .. ..$ type     : 'scalar' chr "bar"
##   .. ..$ variables: chr "cyl"
##   .. ..$ id       : 'scalar' chr "97fe3d39-3ff4-4c8b-9635-693143678cdb"
```

As you can see, the object created with `create_schema` is essentially just a `list` of messages. Modifying the schema by calling functions such as `add_scatterplot` or `set_scale` simply appends a new message to the list, similar to how objects of class `ggplot` are modified by the corresponding functions and the `+` operator in `ggplot2` [@wickham2016]. This design makes it easy to transport schemas (e.g. as JSON) and modify them programmatically. Finally, rendering the schema into a figure requires an explicit call to `render`. Note that this approach is different from the popular R convention of rendering implicitly via a `print` method; however, there is a good reason for this design choice which will be discussed later. 

The call to `render` turns the schema gets turned into a live, interactive figure by constructing an `htmlwidgets` widget [@htmlwidgets2021]. This bundles up the underlying data and `plotscape` code (JavaScript, HTML, CSS) into a standalone HTLM document, which may be served live, such as in RStudio viewer, or statically embedded in another HTML document, such as one produced with RMarkdown. All of the schema messages also get forwarded to the widget and applied sequentially, creating the figure.

Note that, under this model, the schema merely records state-generating steps, not the state itself. In other words, all of the state lives on the scene (the client-side figure). This design avoids state duplication between the R session (server) and web-browser-based figure (client), eliminating the need for synchronization.

While this client-heavy approach deviates from the typical client-server architecture, where most of state resides on the server, it is essential for achieving highly-responsive interactive visualizations. By keeping most of the state on the client, we avoid round-trips to the server, resulting in fast updates in response to user interaction. For instance, linked selection updates, triggered by mousemove events, can be computed directly on the client and instantly rendered. Conversely, this is also why server-centric frameworks like Shiny [@shiny2024] struggle with latency-sensitive interactive features like linked selection. Finally, as will be discussed below, while the R session (server) may occasionally send and receive messages, their latency requirements are significantly less stringent, making a "thin" server perfectly viable.

### Client-server communication {#client-server}

When inside an interactive R session (e.g., in RStudio IDE [@rstudio2024]), creating a `plotscaper` figure via calling `render` also automatically launches a WebSockets server [using the `httpuv` package, @cheng2024]. This server allows live, two-way communication between the R session (server) and the figure (client). By assigning the output of the `render` call to a variable, users can save a handle to this server, which can be then used to call functions which query the figure's state or cause mutable, live updates. For instance:


``` r
# The code in this chunk is NOT EVALUATED - 
# it only works only inside interactive R sessions,
# not inside static RMarkdown/bookdown documents.

scene <- create_schema(mtcars) |>
  add_scatterplot(c("wt", "mpg")) |>
  add_barplot(c("cyl")) |>
  render()

# Render the scene
scene

# Add a histogram, modifying the figure in-place
scene |> add_histogram(c("disp"))

# Set the scatterplot's lower x-axis limit to 0 (also in-place)
scene |> set_scale("plot1", "x", min = 0)

# Select cases corresponding to rows 1 to 10
scene |> select_cases(1:10)

# Query selected cases - returns the corresponding
# as a numeric vector which can be used in other
# functions or printed to the console
scene |> selected_cases() # [1] 1 2 3 4 5 6 7 8 9 10
```

As noted earlier, most `plotscaper` functions are polymorphic `S3` methods which can accept either a schema or a scene as the first argument. When called with schema as the first argument, they append a message to the schema, whereas when called with scene as the first argument, they send a WebSockets request, which may either cause a live-update to the figure or have the client respond back with data (provided we are inside an interactive R session). In more abstract terms, with respect to these methods, the `render` function is a functor/homomorphism, meaning that we can either call these methods on the schema and then render it, or immediately render the figure and then call the methods, and the result will be the same (provided no user interaction happens in the meantime). The exception to this rule are state-querying functions such as `selected_cases`, `assigned_cases`, and `get_scale`. These functions send a request to retrieve the rendered figure's state and so it makes little sense to call them on the schema^[Of course, we *could* always parse the list of messages to compute the figure's state on demand, as it will be when the figure gets rendered. For instance with `create_schema(...) |> assign_cases(1:10, 2) |> assign_cases(5:10, 3)` we could parse the messages to infer that the first five group indices will belong to group 2 and the second five will belong to group 3. However, since the user has to explicitly write the code to modify the figure's state, the utility of this hypothetical parsing mechanism is debatable.].

### HTML embedding

As `htmlwidgets` widgets, `plotscaper` figures are essentially static webpages. As such, they can be statically embedded in HTML documents such as those produced by RMarkdown [@rmarkdown2024] or Quarto [@allaire2024]. More specifically, when a `plotscaper` figure is rendered, `htmlwidgets` [@htmlwidgets2021] is used to bundle the underlying HTML, CSS and JavaScript. The resulting widget can then be statically embedded in any valid HTML document, or saved as a standalone HTML file using the `htlwidgets::saveWidget` function. This is in fact how `plotscaper` figures are rendered in the present thesis. 

As mentioned above, since client-server communication requires a running server, statically rendered figures cannot be interacted with through code, in the way described in Section \@ref(client-server). However, within-figure interactive features such as linked selection and querying are entirely client-side, and as such work perfectly fine in static environments. This makes `plotscaper` a very useful and convenient tool to use in interactive reports. 

## Low-level implementation (`plotscape`) {#low-level-implementation}

This section describes the actual platform used to produce and manipulate interactive figures, as implemented in `plotscape`. I begin with the discussion of some broader concerns, specifically the choice of programming paradigm (Section \@ref(programming-paradigm)), data representation (Section \@ref(row-column)), and reactivity model (Section \@ref(reactivity). Finally, I provide a detailed listing of the system's components and their functionality (Section \@ref(components)). Some readers may potentially find it easier to start with Section \@ref(components), as this presents the most concrete and granular information.

Key concepts are explained via example code chunks. All of these represent valid TypeScript code, and selected examples are even evaluated, using the [Bun](https://bun.sh/) TypeScript/JavaScript runtime [@bun2025]. The reason why TypeScript was chosen over R for the examples is that explicit type signatures make many of the concepts much easier to explain. Further, since `plotscape` is written in TypeScript, many of the examples are taken directly from the codebase, albeit sometimes modified for consistency or conciseness.

### Programming paradigm {#programming-paradigm}

The first broad issue worth briefly discussing is the choice of programming paradigm for `plotscape`. A programming paradigm is a set of rules for thinking about and structuring computer programs. Each paradigm offers guidelines and conventions regarding common programming concerns, including data representation, code organization, and control flow. 

While most programming languages tend to be geared towards one specific programming paradigm [see e.g. @van2009], the languages I chose for my implementation - JavaScript/TypeScript and R - are both multi-paradigm languages [@chambers2014; @mdn2024c]. As C-based languages, both support classical procedural programming. However, both languages also have first-class function support, allowing for a functional programming style [@chambers2014; @mdn2024e], and also support object-oriented programming, via prototype inheritance in the case of JavaScript [@mdn2024d] and the S3, S4, and R6 object systems in the case of R [@wickham2019]. This made it possible for me to try out several different programming paradigms while developing `plotscape`/`plotscaper`. 

I did not find it necessary to discuss the choice of programming paradigm in Section \@ref(high-level-api), since I did not delve into any specific implementation details there. However, I believe it is important to discuss it now, as I will be going into implementation details in the following sections. Therefore, in the following subsections, I will briefly outline four programming paradigms - object-oriented, functional, and data-oriented programming - discussing their key features, trade-offs, and suitability for interactive data visualization. I will then provide a rationale for my choice of programming paradigm and discuss my specific use of it in `plotscape`.

#### Procedural programming

Procedural programming, also known as imperative programming^[Technically, some authors consider procedural programming a subset of imperative programming, such that procedural programming is imperative programming with functions (procedures) and scopes, however, the terms are often used interchangeably.], is perhaps the oldest and most well-known programming paradigm. Formalized by John Von Neumann in 1945 [@von1993; for a review, see @knuth1970; @eigenmann1998], it fundamentally views programs as linear sequences of discrete steps that modify mutable state [@frame2014]. These steps can be bundled together into functions or procedures, however, ultimately, the whole program is still thought of as a sequence of operations. In this way, it actually closely maps onto how computer programs get executed on the underlying hardware [beyond some advanced techniques such as branch prediction and speculative execution, the CPU executes instructions sequentially, see e.g. @parihar2015; @raghavan1998].

Compared to the other three programming paradigms discussed below, the procedural programming paradigm is, generally, a lot less prescriptive. It essentially acts as a framework for classifying fundamental programming constructs (variables, functions, loops, etc.), and offers minimal guidance on best practices or program structure. Most programming languages offer at least some procedural constructs, and thus many programs are at least partly procedural.

As for the suitability of procedural programming for interactive data visualization, there are some pros and cons. The fact that programs written in procedural style map fairly closely onto CPU instructions means that, generally, they tend to be highly performant; for instance, it is generally considered good practice to use procedural (imperative) code in "hot" loops [see e.g. @acton2014]. However, a purely procedural style can introduce challenges when developing larger systems. Specifically, since the procedural style imposes few restrictions on the program structure, without careful management, it can lead to complex and hard-to-extend code.   

#### Functional programming {#functional}

Functional programming is another fairly well-known and mature programming paradigm. With roots in the lambda calculus of Alonzo Church [@church1936; @church1940; for a brief overview, see e.g. @abelson2022; @frisby2025], functional programming centers around the idea of function composition. In this paradigm, programs are built from pure, side-effect-free functions which operate on immutable data. Further, functions are treated as first-class citizens, allowing functions to take other functions as arguments or return them (functions which do this are called "higher-order functions"). This approach ultimately leads to programs that resemble data pipelines, transforming input to output without altering mutable state.

A key benefit of the functional approach is referential transparency [see e.g. @abelson2022; @frisby2025; @milewski2018; @stepanov2009]. Because pure functions have no side effects, expressions can always be substituted with their values and vice versa. For example, the expression `1 + 2` can be replaced by the value `3`, so if we define a function `function add(x, y) { return x + y; }`, we can always replace its call with the expression `x + y`. This property is incredibly useful as it allows us to reason about functions independently, without needing to consider the program's state. However, referential transparency only holds if the function does not modify any mutable state; assigning to non-local variables or performing IO operations breaks this property, necessitating consideration of program state when the function is called.

Relevant to this thesis, functional programming is also closely linked to mathematics, particularly category theory [see @milewski2018]. Many algebraic concepts discussed in Section \@ref(problems) – including preorders, functors, and monoids – have direct counterparts in many functional programming languages. These are often implemented as type classes, enabling polymorphism: for instance, in Haskell [@haskell1970], users can define an arbitrary monoid type class which then allows aggregation over a list [@haskell2019].

Again, when it comes to interactive data visualization, the functional programming style presents some fundamental trade-offs. While properties like referential transparency are attractive, all data visualization systems must ultimately manage mutable state, specifically the graphical device. Further, user interaction also adds additional complexity which is challenging to model in a purely functional way (although it is certainly possible; see Section \@ref(streams)). This might explain the lack of purely functional interactive data visualization libraries, despite the existence of functional libraries for static visualization [see e.g. @petricek2021]. Nevertheless, many functional programming concepts remain valuable even outside of purely functional systems. For example, a system may work with mutable state while remaining largely composed of pure functions [by "separating calculating from doing", see @normand2021; @vaneerd2024].

#### Object-oriented programming {#oop}

Compared to the two programming paradigms discussed before, object oriented programming (OOP) is a more recent development, however, it is also a fairly mature and widely-used framework. It first appeared in the late 1950's and early 1960's, with languages like Simula and Smalltalk, growing to prominence in the 1980's and 1990's and eventually becoming an industry standard in many areas [@black2013].

The central idea of object-oriented programming is that of an objects. Objects are self-contained units of code which own their own, hidden, private state, and expose only a limited public interface. Objects interact by sending each other messages [@meyer1997], a design directly inspired by communication patterns found in the networks of biological cells [as reported by one of the creators of Smalltalk and author of the term "object-oriented" @kay1996]. Beyond that, while concrete interpretations of object oriented programming differ, there are nevertheless several ideas which tend to be shared across most OOP implementations.

These core ideas of OOP are: abstraction, encapsulation, polymorphism, and inheritance [@booch2008]. Briefly, first, abstraction means objects should be usable without the knowledge of their internals. Users should rely solely on the public interface (behavior) of an object simplifying reasoning and reducing complexity [@black2013; @meyer1997]. Second, encapsulation means that the surface area of an object should be kept as small as possible and the internal data should be kept private [@booch2008]. Users should not access or depend on this hidden data [@meyer1997]. The primary goal of encapsulation is continuity, allowing developers to modify an object's private properties without affecting the public interface [@booch2008; @meyer1997]. Third, polymorphism means that objects supporting the same operations should be interchangeable at runtime [@booch2008]. Polymorphism is intended to facilitate extensibility, allowing users to define their objects that can be integrated into an existing system. Finally, inheritance is a mechanism used for code reuse and implementing polymorphism, where objects may inherit properties and behavior from other objects.

Object-oriented programming (OOP) has been widely adopted, especially for graphical user interfaces (GUIs). Given the significant GUI component in interactive data visualization systems, OOP might seem like an obvious first choice. Furthermore, OOP's claimed benefits of continuity and extensibility appear highly valuable for library design. However, more recently, OOP has also come under criticisms, for several reasons. First, while the ideas of reducing complexity via abstraction, encapsulation, and polymorphism seem attractive, applied implementations of OOP do not always yield these results. Specifically, a common practice in OOP is for objects to communicate by sending and receiving pointers to other objects; however, this breaks encapsulation, causing the objects to become entangled and creating "incidental data structures" [@hickey2011; @parent2015; @will2016]. Second, by its nature, OOP strongly encourages abstraction, and while good abstractions are undeniably useful, they take long time to develop. Poor abstractions tend to appear first [@meyer1997], and since OOP tends to introduce abstractions early, it can lead to overly complex and bloated systems [@vaneerd2024]. Third and final, OOP can also impact performance. Objects often store more data than is used by any single one of their methods, and further, to support runtime polymorphism, they also have to store pointers to a virtual method tables. Consequently, an array of objects will almost always take up more memory than an equal-sized array of plain values, resulting in increased cache misses and decreased performance [@acton2014].   

#### Data-oriented programming {#dop}

Compared to the three previously discussed paradigms, data-oriented programming (DOP) is a more recent and less well-known programming paradigm. In fact, due to its novelty, the term is also used somewhat differently across different contexts, broadly in two ways. First, DOP sometimes refers to a more abstract programming paradigm, concerned with structure and organization of code and inspired by the Clojure style of programming [@hickey2011; @hickey2018; @sharvit2022; @parlog2024]. In this way, it also shares many similarities with the generic programming paradigm popularized by Alexander Stepanov and the related ideas around value semantics [@stepanov2009; @stepanov2013; @parent2013; @parent2015; @parent2018; @vaneerd2023; @vaneerd2024], and there are even some direct ties [see @vaneerd2024]. Second, DOP (or "data oriented design", DOD) also sometimes refers to a more concrete set techniques and ideas about optimization. Originating in video-game development, these primarily focus on low-level details like memory layout and CPU cache line utilization [@acton2014; @bayliss2022; @kelley2023; @nikolov2018; @fabian2018].  Interestingly, despite these two distinct meanings of the term DOP, both converge on similar ideas regarding the structure and organization of computer programs, and as such, I believe it is justified to discuss them here as a single paradigm.

The core idea of DOP is a data-first perspective: programs should be viewed as transformations of data [@acton2014; @fabian2018; @sharvit2022]. This has several consequences, the most important of which is the separation of code (behavior) and data [@fabian2018; @sharvit2022; @vaneerd2024]. Data should be represented by plain data structures, composed of primitives, arrays, and dictionaries [a typical example would be [JSON](#JSON), @hickey2011; @hickey2018; @sharvit2022]. In other words, the data should be trivially copyable and behave like plain values [see @stepanov2009; @stepanov2013]. Furthermore, it should be organized in a way that is convenient and efficient; there is no obligation for it to model abstract or real-world entities [@acton2014; the fundamental blueprint is that of the relational model, @codd1970; @moseley2006; @fabian2018]. Code, on the other hand, should live inside modules composed of stateless functions [@fabian2018; @sharvit2022]. The primary benefit of this approach is that, by keeping data and code separate, we can reason about both in isolation, without entanglement [@vaneerd2024]. It also allows us to introduce abstraction gradually, by initially relying on generic data manipulation functions [@fabian2018; @sharvit2022]. Finally, it also enables good performance: by storing plain data values and organizing them in a suitable format (for example, structure of arrays, see Section \@ref(row-column)), we can ensure optimal cache line utilization [@acton2014; @fabian2018; @kelley2023;]. 

As might be apparent, data oriented programming shares some similarities with procedural and functional programming, but there are also some key differences. Compared to the lasseiz-faire approach of procedural programming, DOP tends to be a lot more opinionated about the structure of programs. Furthermore, while its focus on stateless functions might suggest a resemblance to functional programming, DOP generally does not prohibit mutation, and its emphasis on plain data over abstract behavior contrasts with the often highly abstract nature of purely functional code. As such, in my view, the ideas in DOP represent a distinct and fully-formed programming paradigm. 

While DOP is a novel programming paradigm, there is a precedence for similar ideas in data visualization systems. Specifically, the popular tendency of defining plots via declarative schemas (see e.g. Section \@ref(variables-encodings)) seems to align well with DOP principles. While this generally tends to be a feature of the packages' public facing APIs, not necessarily the implementation code, the popularity of JSON-like schemas might suggest that this style might be useful in designing data visualization packages more broadly.  

#### Final choice of programming paradigm and rationale

Thanks to TypeScript/JavaScript (and R) being a multi-paradigm programming language, I was able to experiment with several programming paradigms. During initial prototyping, I used primarily procedural style, but I also explored some functional programming concepts. Later, I completely rewrote the package using traditional OOP style, but found some aspects of it frustrating and challenging. Particularly, with multiple communicating objects, I found it difficult to cleanly separate concerns and reason about complex interactive behavior. Eventually, I discovered DOP and ultimately settled on that style, finding that the plain data model greatly simplified a lot of the problems I had.

In my view, the primary advantage of DOP was the ability to reason about data and behavior separately. Many parts of the system, such as dataframes and scales (see Sections \@ref(dataframe) and \@ref(scales)), make sense to think about as primarily composed of plain data. Modeling them this way helps avoid much of the entanglement which is arguably inherent to traditional OOP objects. Specifically, plain data structures composed of primitives, arrays, and dictionaries naturally tend to form simple tree-like structures, rather than more complex graphs with potential circular references, simplifying reasoning [@parent2013; @parent2015; @vaneerd2024]^[Technically, in JavaScript, there is no difference on the language level: all array and dictionary ([POJO](#JSON)) variables are pointers to (heap-allocated) objects, so they can be referenced in multiple places. However, conceptually, I still found it much easier to think about data structures in the DOP way.]. Further, defining behavior in pure function modules made it much easier to refactor and test. I also believe it encouraged a more conservative coding style: the requirement to pass all data explicitly as arguments, rather than relying on implicit class properties (members), made me more disciplined, by encouraging me to pass on only the necessary data and nothing more. Finally, it greatly simplified scenarios requiring double (multiple) dispatch; instead of deciding which class a method should belong to and which it should dispatch on, I could simply write a free function dispatching on both.

The only place where I found myself reverting to OOP-like idioms was in the several areas requiring polymorphism. Specifically, while for most of the system, polymorphism is pure overhead (in my opinion), for certain components like scales, the ability to dispatch based on the underlying data type is desirable. Further, giving the users the ability to extend the system by implementing their own components is of course useful. However, instead of using classes, I implemented a custom dispatch mechanism myself. While, hypothetically, traditional OOP classes may be a decent solution here, I found that maintaining consistent style with the rest of the codebase was preferable. 

While I did not attempt a purely (or even largely) functional implementation of `plotscape`, I believe there are several reasons why it might not be the optimal choice either. First, as mentioned in Section \@ref(functional), data visualization inherently requires dealing with significant amount of mutable state (the graphical device). Further, user interaction adds another element that is challenging to model in a purely functional style. While techniques for handling both do exist [see e.g. @abelson2022; @frisby2025], and so do functional programming data visualization libraries [see e.g. @petricek2021], I personally question whether the increased complexity is worthwhile. Second, similar to OOP, a purely functional style tends to introduce a high amount of abstraction. While good abstractions are incredibly powerful, I found that, generally, refactoring poorly-organized plain data containers was much easier than refactoring abstract constructs, be they classes or higher-kinded types.  

Finally, while my preference for DOP might also be partly due to the fact that, over the course of the project, I naturally improved as a programmer, I do not believe that this is the full explanation. Even after settling on DOP, I have experimented with other paradigms but consistently find myself returning to DOP. While there are of course many less-than-perfectly-tidy areas of the `plotscape` codebase that could be refactored, I still believe that this less programming paradigm allowed me, a solo developer with limited time, to go further and develop more features without becoming overwhelmed by inherent complexity. Therefore, I felt it necessary to explain my choice of programming paradigm.  

#### Style used in code examples

Another part of the reason why I spent time discussing the choice of the programming paradigm used in `plotscape` is because it is reflected in many of the code examples used throughout the rest of this chapter. Specifically, in these examples, I typically define a data container as a TypeScript `interface` and a collection of related functions in a `namespace` of the same name. Since TypeScript transpiles to JavaScript, and all of the type information is compile-time only, type (`interface`) and value (`namespace`) overloading like this is perfectly valid.

In some ways, this interface-namespace style might seem like object-oriented programming (OOP) with extra steps, i.e. where someone might write `const foo = new Foo(); const bar = foo.bar()`, I write `const foo = Foo.create(); const bar = Foo.bar(foo)`, however, there are a couple of important differences. First, unlike a class that tightly couples data and behavior, the interface-defined type is solely a data container, and the namespace is merely a container for free functions. As such, both can be reasoned about in isolation. Second, TypeScript's structural typing enables calling the namespace functions with *any* variable matching the type signature, not just class instances, significantly improving code reusability. Finally, unlike classes, the interface-defined types are simple data containers without polymorphism, and this eliminates the need for dynamic dispatch (in the general case), potentially improving performance. Overall, the style aligns with the data-oriented programming principles discussed in Section \@ref(dop).

### Data representation: Row-oriented vs. column-oriented {#row-column}

Data visualization is fundamentally about the data; however, the same data can often be represented in multiple ways. This is important as different data representations have can offer different trade-offs, including ease of use and performance. In most data analytic applications, the fundamental data model is that of a two-dimensional table or dataframe. However, because computer memory is inherently one-dimensional, a choice must be made: should these tables be stored as arrays of heterogeneous records (rows) or as a dictionaries of homogeneous arrays (columns)?

In popular, in-memory data analytics applications, the column-store seems to be the prevaling model. This model organizes tables as dictionaries of columns, such that each column is a homogeneous array containing values of the same type. Unlike a matrix, however, different columns can store values of different types (e.g. floats, integers, or strings). Dataframe objects may also store optional metadata, such as row names, column labels, or grouping structures [@r2024; @bouchet-valat2023]. Popular examples of this design include the S3 `data.frame` class in base R [@r2024], the `tbl_df` S3 class in the `tibble` package [@muller2023], the `DataFrame` class in the Python `pandas` [@pandas2024], the `DataFrame` class in the `polars` [@polars2024], or the `DataFrame` type in the Julia `DataFrame.jl` package [@bouchet-valat2023].

However, there are also some fairly well-known examples of row-oriented systems. Particularly, the popular JavaScript data visualization and transformation library D3 [@bostock2022] models data frames as arrays of rows, with each row being a JavaScript object. Likewise, row-stores are also highly popular in databases, particularly in online transaction processing (OLTP) systems such as PostgreSQL, SQLite, or MySQL, where tables are generally stored as arrays of records, both in memory and on disk [see e.g. @petrov2019; @abadi2013; @pavlo2024].

Finally, within the broader programming context, the two data models are also known as the struct-of-arrays (SoA) and array-of-structs (AoS) layouts, corresponding roughly to the column- and row-store, respectively [see e.g. @acton2014; @kelley2023]. Here, the distinction is a bit more nuanced, since the stored data may be interpreted as more than just plain values, making either representation more or less natural in certain programming paradigms (see Section \@ref(programming-paradigm)). For example, in object-oriented programming (OOP), the fundamental unit of code is an object (see Section \@ref(oop)). Since objects are meant to encapsulate their properties - both data and behaviour (via a pointer to a virtual method table) - the AoS layout, which keeps object properties adjacent in memory, is the more natural choice in OOP [see e.g. @bayliss2022].

#### Ease of use

When it comes to user experience, the row-oriented (AoS) model may be slightly easier for novice users; however, this difference is probably fairly minor. While many data analysis workflows involve row-oriented operations, which, in the row-oriented model, can be performed by indexing the array of rows once (rather than requiring indexing across multiple columns), many column-oriented applications also provide support for row operations, either through library functionality [e.g., pandas, @pandas2024], or directly at the language level [e.g., R, @r2024]. Furthermore, the prevalence of column-oriented workflows within the data science ecosystem means that many users will be already familiar with this layout. Therefore, on balance, I believe that, in terms of user experience, there is little difference between the two data layouts.
 
#### Performance {#row-column-performance}

A key factor determining the performance of row-oriented vs. column-oriented storage is the intended use. Specifically, depending on how the store is intended to be used, one layout may provide better performance characteristics than the other.

The column-oriented (SoA) layout tends to be the more performant option for storage and operations across multiple rows, particularly aggregation [see e.g. @acton2014; @kelley2023; @pavlo2024]. This is due to the fact that it benefits from better memory alignment and, as a result, improved cache locality. Because all values within a column share the same size, this eliminates the need for padding, often resulting in a significantly smaller memory footprint [see e.g. @rentzsch2005; @kelley2023; @pavlo2024]. Furthermore, this uniform sizing also facilitates easier pre-fetching of values during column-wise operations. Specifically, the CPU can cache contiguous chunks of values, often leading to greatly improved performance for operations such as summing a long list of values [@abadi2013; @acton2014; @kelley2023; @pavlo2024]. This has made the column-oriented layout the preferred solution in online analytical processing (OLAP) databases [@abadi2013; @pavlo2024].

In contrast, the row-oriented (AoS) layout performs better at single-row read and write operations. Because all values for a record are stored contiguously, they can be retrieved without needing to be fetched and assembled from disparate memory locations. Similarly, writes are faster as only a single memory location needs to be modified. These characteristics have made the row-oriented layout the traditional choice in OLTP databases [@abadi2013; @pavlo2024].

An important point to mention is that, in high-level languages like JavaScript, the underlying memory representation may differ significantly from the apparent structure. For instance, to optimize key access, the V8 engine stores JavaScript objects (dictionaries) as "hidden classes": essentially a pointer to the object's shape and an array of values [@bruni2017; @veight2024]. Nevertheless, objects are still allocated on the heap, unlike packed arrays of small integers (SMIs) or floats, which consequently tend to offer much better performance characteristics [see e.g. @veight2017; @bruni2017; @stange2024].     

#### Final choice of data representation and rationale

As an interactive data visualization system, plotscape needed to support fast data transformations. Particularly, for linked selection, efficient aggregations were key. As such, the column-oriented data layout was chosen. While this approach differs from that of the most popular web-based data visualization framework [D3, Bostock, 2022], it aligns with the majority of other data analytic languages and libraries.

### Reactivity {#reactivity}

A key implementation detail of all interactive applications is reactivity: how a system responds to input and propagates changes. However, despite the fact that interactive user interfaces (UIs) have been around for a long time, there still exist many different, competing approaches to handling reactivity. A particularly famous^[Or perhaps infamous.] example of this is the web ecosystem, where new UI frameworks seem to keep emerging all the time, each offering its unique spin on reactivity [see e.g. @ollila2022]. This makes choosing the right reactivity model challenging. 

Furthermore, reactivity is paramount in interactive data visualization systems due to many user interactions having cascading effects. For instance, when a user changes the binwidth of an interactive histogram, the counts within the bins need to be recomputed, which in turn means that scales may need to be updated, which in turn means that the entire figure may need to be re-rendered, and so on. Also, unlike other types of UI applications, interactive data visualizations have no upper bound on the number of UI elements - the more data the user can visualize the better. This makes efficient updates crucial. While re-rendering a button twice may not be a big deal for a simple webpage or GUI application, unnecessary re-renders of a scatterplot with tens-of-thousands of data points may cripple an interactive data visualization system. 

Because of the reasons outlined above, reactivity was key concern for `plotscape`. While developing the package, I had evaluated and tried out several different reactivity models, before finally settling on a solution. Given the time and effort invested in this process, I believe it is valuable to give a brief overview of these models and discuss their inherent advantages and disadvantages, before presenting my chosen approach in Section \@ref(reactivity-solution). 

#### Observer pattern {#observer}

One of the simplest and most well-known methods for modeling reactivity is the Observer pattern [@gamma1995]. Here's a simple implementation: 


``` ts
// Observer.ts
export namespace Observer {
  export function create<T>(x: T): T & Observer {
    return { ...x, listeners: {} };
  }

  export function listen(x: Observer, event: string, cb: () => void) {
    if (!x.listeners[event]) x.listeners[event] = [];
    x.listeners[event].push(cb);
  }

  export function dispatch(x: Observer, event: string) {
    if (!x.listeners[event]) return;
    for (const cb of x.listeners[event]) cb();
  }
}

const person = Observer.create({ name: `Joe`, age: 25 });
Observer.listen(person, `age-increased`, () =>
  console.log(`${person.name} is now ${person.age} years old.`)
);

person.age = 26;
Observer.dispatch(person, `age-increased`);
```

Internally, an `Observer` object stores a dictionary where the keys are the events that the object can dispatch or notify its listeners of, and values are arrays of callbacks^[In simpler implementations, a single array can be used instead of the dictionary; the listeners are then notified whenever the object "updates".]. Listeners listen (or "subscribe") to specific events by adding their callbacks to the relevant array. When an event occurs, the callbacks in the appropriate array are iterated through and executed in order.

The `Observer` pattern easy to implement and understand, and, compared to alternatives, also tends to be fairly performant. However, a key downside is that the listeners have to subscribe to the `Observer` manually. In other words, whenever client code uses `Observer` values, it needs to be aware of this fact and subscribe to them in order to avoid becoming stale. Further, the logic for synchronizing updates has to be implemented manually as well. For instance, by default, there is no mechanism for handling dispatch order: the listeners who were subscribed earlier in the code are called first^[This can be solved by adding a priority property to the event callbacks, and sorting the arrays by priority.]. Moreover, shared dependencies can cause glitches and these have to be resolved manually as well. See for instance the following example:


``` ts
import { Observer } from "./Observer"

function update(x: { name: string; value: number } & Observer, 
                value: number) {
  x.value = value;
  console.log(`${x.name} updated to`, x.value);
  Observer.dispatch(x, `updated`);
}

const A = Observer.create({ name: `A`, value: 1 });
const B = Observer.create({ name: `B`, value: A.value * 10 });
const C = Observer.create({ name: `C`, value: A.value + B.value });

Observer.listen(A, `updated`, () => update(B, A.value * 10));
Observer.listen(A, `updated`, () => update(C, A.value + B.value));
Observer.listen(B, `updated`, () => update(C, A.value + B.value));

update(A, 2); // C will get updated twice
```

The example above shows the so-called diamond problem in reactive programming^[Not to be confused with the diamond problem in OOP, which relates to multiple inheritance.]. We have three reactive variables `A`, `B`, and `C`, such that `B` depends on `A`, and `C` depends simultaneously on `A` and `B`. Since `C` depends on `A` and `B`, it has to subscribe to both. However, `C` is not aware of the global context of the reactive graph: it does not know that `B` will update any time `A` does. As such, an update to `A` will trigger *two* updates to `C` despite the fact that, intuitively, it should only cause one. 

Without careful management of dependencies, this reactive graph myopia that the `Observer` pattern exhibits can create computational bottlenecks, particularly in high-throughput UIs such as interactive data visualizations. Consider an interactive histogram where users can either modify binwidth or directly set breaks. If both are implemented as reactive parameters, a poorly managed dependency graph (e.g., breaks dependent on binwidth, and rendering dependent on both) will result in unnecessary re-renders, impacting performance at high data volumes.

#### Streams {#streams}

A radically different approach to reactivity is offered by streams [see e.g. @abelson2022]. Instead of events directly modifying data state, streams separate event generation from event processing, modeling the latter as pure, primarily side-effect-free transformations. These transformations can then be composed via usual function composition to build arbitrarily complex processing logic. Finally, due to the separation between the stateful event producers and stateless event transformations, this approach aligns closely with methods such as generators/iterators as well as functional programming more broadly [@abelson2022; @fogus2013], and has implementations in numerous functional programming languages and libraries, most notably the polyglot Reactive Extensions library [also known as ReactiveX, @reactive2024].

Consider the following implementation of a stream which produces values at 200-millisecond intervals and stops after 1 second: 


``` ts
function intervalSteam(milliseconds: number, stopTime: number) {
  let streamfn = (x: unknown) => x;
  const result = { pipe };

  function pipe(fn: (x: any) => unknown) {
    const oldStreamfn = streamfn;
    streamfn = (x: unknown) => fn(oldStreamfn(x));
    return result;
  }

  const startTime = Date.now();
  let time = Date.now();

  const interval = setInterval(() => {
    time = Date.now();
    const diff = time - startTime;
    if (diff >= stopTime) clearInterval(interval);
    streamfn(diff);
  }, milliseconds);

  return result;
}

const stream = intervalSteam(200, 1000)


stream
  .pipe((x) => [x, Math.round((x / 7) * 100) / 100])
  .pipe((x) =>
    console.log(
      `${x[0]} milliseconds has elapsed`
      + `(${x[1]} milliseconds in dog years)`
    )
  );
```

As you can see, the event producer (stream) is defined separately from the event processing logic, which is constructed by piping the result of one operation into the next. Because of the associativity of function composition, the stream actually exhibits properties of a functor, meaning that the order of composition - either through direct function composition or `.pipe` chaining - does not affect the result. Additionally, while the stream transformations themselves are (generally) stateless, they can still produce useful side-effects (as can be seen on the example of the `console.log` call above). Further, because of this fact, they also lend themselves well to modeling asynchronous or even infinite data sequences [@abelson2022; @fogus2013].

While streams can be extremely useful in specific circumstances, their utility as a general model for complex UIs (beyond asynchronous operations) is debatable. Specifically, the inherent statefulness of UIs conflicts with the stateless nature of streams: stateless computations inside the stream have to leak into the rest of the application *somewhere*. Delineating which parts of the logic should go into streams versus which should be bound to UI components adds unnecessary complexity for little real benefit. Consequently, streams are likely not the optimal choice for interactive data visualization, where some mutable state is unavoidable. 

#### Virtual DOM

Within the web ecosystem, a popular way of handling reactivity involves something called the virtual DOM (VDOM). This approach, popularized by web frameworks such as React [@react2024] and Vue [@vue2024], involves constructing an independent, in-memory data structure which provides a virtual representation of the UI in the form of a tree. Reactive events are bound to nodes or "components" of this tree, and, whenever an event occurs, changes cascade throughout the VDOM, starting with the associated component and propagating down through its children. Finally, the VDOM is compared or "diffed" against the actual UI, and only the necessary updates are applied. Note that, despite being named after the web's DOM, the VDOM represents a general concept, not tied to any specific programming environment.

The VDOM provides a straightforward solution to reactive graph challenges such as the diamond problem described in Section \@ref(observer). It can work very well in specific circumstances, as evidenced by the massive popularity of web frameworks such as React or Vue. However, compared to alternatives, it also comes with some significant performance trade-offs. Specifically, events near the root component trigger a cascade of updates which propagates throughout a large portion of the tree, even when there is no direct dependence between these events and the child components. Moreover, since the only way for two components to share a piece of state is through their parent, the model naturally encourages a top-heavy hierarchy, further compounding the issue. Finally, depending on the nature and implementation of the UI, the diffing process may be more trouble than its worth: while in a webpage, updating a single button or a div element is a relatively fast operation, in a data visualization system, it may be more efficient to re-render an entire plot from scratch rather than trying to selectively update it.

#### Signals {#signals}

Another approach to reactivity that has been steadily gaining traction over the recent years, particularly within the web ecosystem, are signals (also known as fine-grained reactivity). Popularized by frameworks such Knockout [@knockout2019] and more recently Solid JS [@solid2024], this approach has recently seen a wave adoptions by many other frameworks including Svelte [@svelte2024] and Angular [@angular2025], and has even seen adoption outside of the JavaScript ecosystem, such as in the Rust-based framework Leptos [@leptos2025].

Signal-based reactivity is built around a core pair of primitives: signals and effects. Signals are reactive values which keep track of their listeners, similar to the `Observer` pattern (Section \@ref(observer)). However, unlike `Observer`s, signals do not need to be subscribed to manually. Instead, listeners automatically subscribe to signals by accessing them, which is where effects come in. Effects are side-effect-causing functions which respond to signal changes, typically by updating the UI, and play a key role in the signal-based automatic subscription model.

While signal-based reactivity might appear complex, its basic implementation is surprisingly straightforward. The following example is based on a presentation by Ryan Carniato, the creator of Solid JS [-@carniato2023]:


``` ts
export namespace Signal {
  export function create<T>(x: T): [() => T, (value: T) => void] {
    // A set of listeners, similar to Observable
    const listeners = new Set<() => void>();

    function get(): T {
      listeners.add(Effect.getCurrent());
      return x;
    }

    function set(value: T) {
      x = value;
      for (const l of listeners) l();
    }

    // Returns a getter-setter pair
    return [get, set];
  }
}

export namespace Effect {
  const effectStack = [] as (() => void)[]; // A stack of effects

  export function getCurrent(): () => void {
    return effectStack[effectStack.length - 1];
  }

  export function create(effectfn: () => void) {
    function execute() {
      effectStack.push(execute);  // Pushes itself onto the stack
      effectfn();                 // Runs the effect
      effectStack.pop();          // Pops itself off the stack
    }

    execute();
  }
}

const [price, setPrice] = Signal.create(100);
const [tax, setTax] = Signal.create(0.15);

// Round to two decimal places
const round = (x: number) => Math.round(x * 100) / 100
const priceWithTax = () => round(price() * (1 + tax()));
// ^ Derived values automatically become signals as well

Effect.create(() =>
  console.log(
    `The current price is` + ` ` +
      `${priceWithTax()}` + ` ` +
      `(${price()} before ${tax() * 100}% tax)`
  )
);

setPrice(200);
setTax(0.12);
```

The key detail to notice is the presence of the global stack of effects. Whenever an effect is called, it first pushes itself onto the stack. It then executes, accessing any signals it needs along the way. These signals in turn register the effect as a listener, by accessing it as the top-most element of the effect stack. When the effect is done executing, it pops itself off the stack. Now, whenever one of the accessed signals changes, the effect re-runs again. Crucially, making a derived reactive value is as simple as writing a callback: if an effect calls a function using a signal, it also automatically subscribes to that signal (see the example of `priceWithTax` above). Importantly, the effect subscribes *only* to this signal and not the derived value itself. In other words, effects only ever subscribe to the leaf nodes of the reactive graph (signals). Derived values computed on the fly (and, if necessary, can be easily memoized^[Memoizing a derived value can be done by creating a new signal and an effect that runs when the original value gets updated.]), and event ordering is simply managed via the runtime call stack.

Signals provide an elegant solution to many problems with reactivity. They automate subscription to events, prevent unnecessary updates, ensure correct update order, and, due to their fine-grained nature, are generally highly performant compared to more cumbersome methods like the virtual DOM. However, again, signals do also introduce their own set of trade-offs. Chief among these, signal's reliance on the call stack for event ordering necessitates their implementation as functions (getter-setter pairs), rather than plain data values. While techniques like object getters/setters or templating [as seen in SolidJS, @solid2024] can be used to hide this fact, it does nevertheless add an extra layer of complexity. Similarly, many features important for performance, like memoization and batching, also require treating signals as distinct from plain data. Having code consist of two sets of entities - plain data and signals - ultimately impacts developer ergonomics.

#### Reactivity in `plotscape` and final thoughts {#reactivity-solution}

At the start of the project, I had used the `Observer` pattern for modeling reactivity. However, I had the idea of letting the users to define reactive parameters that could be used at arbitrary points in the data visualization pipeline. This had led me to explore the various models of reactivity described above, and even do a full rewrite of `plotscape` with signals at one point.

However, eventually, I ended up reverting back to the `Observer` pattern. The primary reason was developer ergonomics. While many properties of signals like the automatic event subscription were appealing, the need to manage both data and signals as distinct entities proved cumbersome. Specifically, deciding which components of my system and their properties should be plain data versus signals added an additional overhead and complicated refactoring. With a bit of practice and careful design, I found that I was able to use the `Observer` pattern without introducing unnecessary re-renders. Moreover, I also found that, in the interactive data visualization pipeline, reactivity can be aligned with the four discrete stages: partitioning, aggregation, scaling, and rendering. Specifically, reactive values can be introduced in batch right at the start of each of these four steps, greatly simplifying the reactive graph. Introducing reactivity at other points seem to offer limited practical benefit. Thus, despite the limitations of the `Observer` pattern, the structured nature of the problem (interactive data visualization pipelines) ultimately makes it a decent solution in my eyes.

### System components {#components}

This section discusses the core components of `plotscape`, detailing their functionality, implementation, and interconnections. The goal is to give an overview and provide a rationale for the design of key parts of the system. As before, TypeScript code examples are provided, and, in general, these map fairly closely to the real codebase.  

#### Indexable {#Indexable}

One of the fundamental considerations when implementing a data visualization system is how to represent a data variable: a generalized sequence of related values. Clearly, the ability to handle fixed-length arrays is essential, however, we may also want to be able to treat constants or derived values as variables. To give an example, in a typical barplot, the y-axis base is a constant, typically zero. While we could hypothetically append an array of zeroes to our data, it is much more convenient and memory efficient to simply use a constant (`0`) or a callback/thunk (`() => 0`). Similarly, at times, arrays of repeated values can be more optimally represented as two arrays: a short array of "labels" and a long array of integer indices (i.e. what base R's `factor` class does). Thus, representing data effectively calls for a generalization of a data "column" which can encompass data types beyond fixed-length arrays.

The type `Indexable<T>` represents such a generalization of a data column. It is simply a union of three simple types: 


``` ts
Indexable<T> = T | T[] | ((index: number) => T)
```

In plain words, an `Indexable<T>` can be one of the following three objects: 

- A simple (scalar) value `T`
- A fixed-length array of `T`'s (`T[]`)
- A function which takes an index as an argument and returns a `T`

That is, `Indexable`s generalize arrays, providing value access via an index. Arrays behave as expected, scalar values are always returned regardless of the index, and functions are invoked with the index as the first argument (this functionality is provided by [`Getter`](#Getter)s). As a final note, `Indexable`s are somewhat similar to Leland Wilkinson's idea of data functions [see @wilkinson2012, pp. 42], although there are some differences (Wilkinson's data functions are defined more broadly).

#### Getter {#Getter}

A `Getter<T>` is used to provide a uniform interface to accessing values from an `Indexable<T>`. It is simply a function which takes an index and returns a value of type `T`. To construct a `Getter<T>`, we take an `Indexable<T>` and dispatch on the underlying subtype. For illustration purposes, here is a simplified implementation: 


``` ts
// Getter.ts
export type Getter<T> = (index: number) => T;

export namespace Getter {
  export function create<T>(x: Indexable<T>): Getter<T> {
    if (typeof x === `function`) return x;
    else if (Array.isArray(x)) return (index: number) => x[index];
    else return () => x;
  }
}

```

we can then create and use `Getter`s like so:


``` ts
import { Getter } from "./Getter"

const getter1 = Getter.create([1, 2, 3])
const getter2 = Getter.create(99);
const getter3 = Getter.create((index: number) => index - 1);

console.log(getter1(0));
console.log(getter2(0));
console.log(getter3(0));
```

Note that, by definition, every `Getter<T>` is also automatically an `Indexable<T>` (since it is a function of the form `(index: number) => T`). This means that we can use `Getter`s to create new `Getter`s. There are also several utility functions for working with `Getter`s. The first is `Getter.constant` which takes in a value `T` and returns a thunk returning `T` (i.e. `() => T`). This is useful, for example, when `T` is an array and we always want to return the whole array (not just a single element):




``` ts
import { Getter } from "./Getter"

const getter4 = Getter.constant([`A`, `B`, `C`])

console.log(getter4(0))
console.log(getter4(1))
```

Another useful utility function is `Getter.proxy`, which takes a `Getter` and an array of indices as input and returns a new `Getter` which routes the access to the original values through the indices:


``` ts
import { Getter } from "./Getter"

const getter5 = Getter.proxy([`A`, `B`, `C`], [2, 1, 1, 0, 0, 0]);
console.log([0, 1, 2, 3, 4, 5].map(getter5))
```

This function becomes particularly useful when implementing other data structures such as `Factor`s.

#### Dataframe {#dataframe}

In many data analytic workflows, a fundamental data structure is that of a two-dimensional table or dataframe. As discussed in Section \@ref(row-column), we can represent this data structure as either a dictionary of columns or a list of rows, with the column-wise representation having some advantages for analytical workflows. As such, in `plotscape`, I chose to represent `Dataframe` as a dictionary columns. Furthermore, in `plotscape`, a key difference is that all columns are not required to be fixed-length arrays; instead, they can be any [`Indexable`](#indexable)s:


``` ts
interface Dataframe {
  [key: string]: Indexable
}
```

For example, the following is a valid instance of a `Dataframe`:


``` ts
const data = {
  name: [`john`, `jenny`, `michael`],
  age: [17, 24, 21],
  isStudent: true,
  canDrive: (index: number) => data.age[index] > 18,
};
```

Most functions in `plotscape` operate column-wise, however, here's how the dataframe above would look like as a list of rows if we materialized using a `Dataframe.rows` function^[Not actually exported by `plotscape` but easily implemented.]:




``` ts
import { Dataframe } from "./Dataframe"

const data = {
  name: [`john`, `jenny`, `michael`],
  age: [17, 24, 21],
  isStudent: true,
  canDrive: (index: number) => data.age[index] > 18,
};

console.log(Dataframe.rows(data))
```

One important thing to mention is that, since the `Dataframe` columns can be different `Indexable` subtypes, we need to make sure that information about the number of rows is present and non-conflicting. That is, all fixed-length columns must have the same length, and, if there are variable-length columns (constants, derived variables/functions) present, we need to make sure that at least one fixed-length column is present in the data (or that the variable-length columns carry appropriate metadata).

While in a traditional OOP style, these length constraints might be enforced by a class invariant, checked during instantiation and maintained inside method bodies, `plotscape` adopts a more loose approach by checking the length constraints dynamically, at runtime. This is done whenever the integrity of a `Dataframe` becomes a key concern, such as when initializing a [`Scene`](#Scene) or when rendering. The approach is more in line with JavaScript's dynamic nature: in JavaScript, all variables (except for primitives) are objects, and there is nothing preventing the users from adding or removing properties at runtime, even to class instances. Further, with `Dataframe`s of typical dimensionality (fewer columns than rows, $p << n$), the performance cost of checking column's length is usually negligible when compared to row-wise operations, such as computing summary statistics or rendering. If performance were to become an issue for high-dimensional datasets ($p >> n$), the approach could always be enhanced with memoization or caching.    

#### Factors

As discussed in Section \@ref(problems), when visualizing, we often need to split our data into a set of disjoint subsets organized into partitions. Further, as mentioned in Section \@ref(hierarchy), these partitions may be organized in a hierarchy, such that multiple subsets in one partition may be unioned together to form another subset in a coarser, parent partition. 

`Factor`s provide a way to represent such data partitions and the associated metadata. They are similar to base R's `factor` S3 class, although there are some important differences which will be discussed below. `Factor` has the following interface:


``` ts
interface Factor<T extends Dataframe> {
  cardinality: number;
  indices: number[];
  data: T
  parent?: Factor;
}
```

Here, `cardinality` represents the number of unique parts that a partitions consists of (e.g. 2 for a binary variable, 3 for a categorical variable with 3 levels, and so on). Data points or cases map to the parts via a "dense" array of `indices`, which take on values in `0 ... cardinality - 1` and have length equal to the length of the data^[The `indices` indices being "dense" means *all* values in the range `0 ... cardinality - 1` appear in the array at least once.]. Each case is identified by its position in the array. For example, take the following array of indices:


``` ts
[0, 1, 1, 0, 2, 0]
```

Keeping in mind JavaScript's zero-based indexing, this array identifies cases one, four, and six as belonging to the first part/level (`0`), cases two and three as belonging to the second part (`1`), and case five as belonging to the third parts (`2`).

The data associated with factor's levels is stored in the `data` property, which is composed of arrays/`Indexables` of equal length as the factor's cardinality. For instance, if a factor is created from a categorical variable with three levels - `A`, `B`, and `C` - then `data` may look something like this: 


``` ts
{ labels: ["A", "B", "C"] }
// In row-oriented form: [{ label: "A" }, { label: "B" }, ... ]
```

Finally, the optional `parent` property is a pointer to the factor representing the parent partition.  

There are a couple of important things to discuss. First, `cardinality` technically duplicates information, since it is simply the number of unique values in `indices`. However, for many operations on `Factor`s, it is beneficial to be able to access cardinality in constant $O(1)$ time. Such is the case, for example, when constructing [product factors](#Product factors) or when initializing arrays of summaries. Of course, this means that the relationship between `cardinality` and `indices` has to be invariant under any factor transformations. 

Second, the metadata associated with the parts is stored in the `data` property of type [`Dataframe`](#Dataframe). This represents a departure from e.g. base R's `factor` class, where all metadata is stored as a flat vector of levels. For instance:


``` r
cut(1:10, breaks = c(0, 5, 10))
```

```
##  [1] (0,5]  (0,5]  (0,5]  (0,5]  (0,5]  (5,10] (5,10] (5,10] (5,10] (5,10]
## Levels: (0,5] (5,10]
```

With `Factor`, the same information would be represented as:


``` ts
const factor: Factor = {
  cardinality: 2,
  indices: [0, 0, 0, 0, 0, 1, 1, 1, 1, 1],
  data: {
    binMin: [0, 5],
    binMax: [5, 10],
  },
};
```

I contend that, compared to a flat vector/array, storing `Factor` metadata in a `Dataframe` offers several distinct advantages. First, when partitioning data, we often want to store multiple metadata attributes. For example, when we bin numeric variable, like in the example above, we want to store both the lower and upper bound of each parts' bin. The approach used in `cut` is to store multiple (two) pieces of metadata as a tuple, however, this becomes cumbersome as the dimensionality of the metadata grows. Further, if metadata is stored in a `Dataframe`, it becomes far easier to combine when taking [a product of two factors](#Product factors). Since factor product is a foundational operation in `plotscape`, underpinning fundamental features such as linked brushing, I argue that it is sensible to store metadata on `Factor` in a full `Dataframe` form.

While all `Factor`s share the same fundamental structure - a data partition with associated metadata - factors can be created using various constructor functions. These constructor functions differ in what data they take as input and what metadata they store on the ouput, giving rise to several distinct `Factor` subtypes. These will be the subject of the next few sections.

##### Bijection and constant factors

`Factor.bijection` and `Factor.constant` are two fairly trival factor constructor. `Factor.bijection` creates the finest possible data partition by assigning every case to its own part, whereas `Factor.constant` does the opposite and assigns all cases to a single part. The names of the reflect the mathematical index mapping functions: the bijective function $f(i) = i$ for `Factor.bijection` and the constant function $f(i) = 0$ for `Factor.constant`. Consequently, the cardinality of `Factor.bijection` is equal to the length of the data, while the cardinality of `Factor.constant` is always one. Both can be assigned arbitrary metadata (which must have length equal to the cardinality).

The two factor constructor functions have the same signature:


``` ts
function bijection<T extends Dataframe>(n: number, data?: T): 
  Factor<T>
  
function constant<T extends Dataframe>(n: number, data?: T): 
  Factor<T> 
```

In either case, `n` represents the length of the data (the number of cases), and `data` represents some arbitrary metadata, of equal length as `n`. The variable `n` is used to construct an array of `indices`, which in the case of `Factor.bijection` is an increasing sequence starting at zero (`[0, 1, 2, 3, ..., n - 1]`), whereas in the case of `Factor.constant` it is simply an array of zeroes (`[0, 0, 0, 0, ..., 0]`). 

Technically, in both of these cases, having an explicit array of indices is not necessary, and we could implement much of the same functionality via a callback (i.e. `(index: number) => index` for `Factor.bijection` and `(index: number) => 0` for `Factor.constant`). However, for many operations involving factors, it is necessary to store the length of the data (`n`), and while it would be possible to define a separate `n`/`length` property on `Factor`, in the context of other factor types, I found it simpler to allocate the corresponding array. While this does incur a small memory cost, there is no computational overhead, since, by definition, the partition represented by a bijection or constant factor does not change^[Unless the length of the data changes. I have not implemented data streaming for `plotscape` yet, however, it would be easy to extend bijection factor for streaming by simply pushing/popping the array of indices.]. 

`Factor.bijection` and `Factor.constant` have their own specific use cases. `Factor.bijection` represents a one-to-one mapping such as that seen in scatterplots and parallel coordinate plots. In contrast, `Factor.constant` represent a constant mapping which assigns all cases to a single part. This is useful for computing summaries across the entirety of the data, such as is required for spinogram^[Other use-cases may be plots involving a single geometric object such as density plots and radar plots, however, these are currently not implemented in `plotscape`.].

As a final interesting side-note, both `Factor.bijection` and `Factor.constant` can be interpreted through the lense of category theory, as terminal and initial objects within the category of data partitions, with morphisms representing products between partitions. That is, the product of any factor with a `Factor.bijection` always yields another `Factor.bijection` (making this a terminal object), whereas the product of any factor with `Factor.constant` will simply yield that factor (making this an initial object).   

##### Discrete factors

Another fairly intuitive factor constructor is `Factor.from`. It simply takes an array of values which can be coerced to string labels (i.e. have the `.toString()` method) and creates a discrete factor by treating each unique label as a factor level (this is essentially what base R's `factor` class does). This gives rise to the following function signature:


``` ts
type Stringable = { toString(): string };
function from(x: Stringable[], options?: { labels: string[] }): 
  Factor<{ label: string[] }> 
```

When creating a discrete factor with `Factor.from`, the resulting factor's length matches the input array `x`. To compute the factor `indices`, the constructor needs to be either provided with an array of `labels` or these will be computed from `x` directly (by calling the `.toString()` method and finding all unique values). Assigning indices requires looping through the $n$ values `x` and further looping through $k$ `labels`, resulting in $O(n)$ time complexity (assuming $k$ is constant with respect to the size of the data). The factor metadata simply contains this array of `label`s (singular form `label` is used since it is the name of a dataframe column). Each index in `indices` then simply maps to one `label`. Finally, for easier inspection, `label`s may be sorted alphanumerically, though this does not affect computation in any way.

The typical use case for `Factor.from` is the barplot. Here, we take an array of values, coerce these to string labels (if the values were not strings already), find all unique values, and then create an array of indices mapping the array values to the unique labels. The indices can then be used to subset data when computing summary statistics corresponding to the barplot bars.

##### Binned factors

Arrays of continuous values can be turned into factors by binning. `Factor.bin` is the constructor function used to perform this binning. It has the following signature:


``` ts
type BinOptions = { 
  breaks?: number[]; 
  nBins?: number; 
  width?: number; 
  anchor?: number; 
}

function bin(x: number[], options?: BinOptions): 
  Factor<{ binMin: number[]; binMax: number[] }>;
```

Again, as in the case of `Factor.from`, the length of the factor created with `Factor.bin` will match the length of `x`. To compute the factor `indices`, the values in `x` need to be assigned to histogram bins delimited by breaks. The breaks are computed based on either default values or the optional list of parameters (`options`) provided to the construct function. Note that the parameters are not orthogonal: for instance, histogram with a given number of bins (`nBins`) cannot have an arbitrary binwidth (`width`) and vice versa. Thus, if a user provides multiple conflicting parameters, they are resolved in the following order: `breaks` > `nBins` > `width`. Finally, the metadata stored on the `Factor.bin` output includes the limits of each bin `binMin` and `binMax`, giving the lower and upper bound of each bin, respectively.

Indices are assigned to bins using a half-open intervals on breaks of the form `(l, u]`, such that a value `v` is assigned to to a bin given by `(l, u]` if it is the case that `l < v <= u`. Assigning indices to bins requires looping through the $n$ values of `x`, and further looping through $k$ `breaks`^[In the general case where the histogram bins are not necessarily all of equal with; if all bins are known to have the same width, we can compute the bin index in constant $O(1)$ time], resulting in $O(n)$ time complexity (assuming $k$ is fixed with respect to the size of the data). 
An important point to mention is that a naive approach of assigning bins to cases may lead to some bins being left empty, resulting in `cardinality` which is less than the number of bins and "sparse" `indices` (gaps in index values). For instance, binning the values `[1, 2, 6, 1, 5]` with breaks `[0, 2, 4, 6]` leaves the second bin (`(2, 4]`) empty, and hence the corresponding index value (`1`) will be absent from `indices`. To address this, `plotscape` performs an additional $O(n)$ computation to "clean" the indices and ensure that the array is dense (i.e. `indices` take on values in `0 ... cardinality - 1`, and each value appears at least once). While this additional computation may not be strictly necessary (i.e. some other systems may use "sparse" factor representation), I found the dense arrays of indices much easier to work with, particularly when it comes to operations like combining factors via products and subsetting the corresponding data. Further, even though this approach necessitates looping over `indices` twice, the combined operation still maintains an $O(n)$ complexity.    

##### Product factors {#product-factors}

As discussed in Section \@ref(products-of-partitions), a fundamental operation that underpins many popular types of visualizations, particularly when linked selection is involved, is the Cartesian product of two partitions. That is, assuming we have two `Factor`s which partition our data into parts, we can create a new `Factor` consists of all unique intersections of those parts.   

To illustrate this idea better, take two factors represented by the following data (the `data` property is omitted for conciseness):


``` ts
{ cardinality: 2, indices: [0, 0, 1, 0, 1, 1] };
{ cardinality: 3, indices: [0, 1, 2, 0, 1, 2] };
```

If we take their product, we should end up with the following factor^[Or a factor isomorphic to that one, up to the permutation of indices.]:


``` ts
{ cardinality: 4, indices: [0, 1, 3, 0, 2, 3] };
```

There are a couple of things to note here. First, note that the cardinality of the product factor (4) is greater than either of the cardinalities of the constituent factors (2, 3), but less than the product of the cardinalities ($2 \cdot 3 = 6$). This will generally be the case: if the first factor has cardinality $a$ and the second cardinality $b$, the product will have cardinality $c$, such that:

- $c \geq a$ and $c \geq a$^[Equality only if either one or both of the factors are constant, or if there exists an isomorphism between the factors' indices.]
- $c \leq a \cdot b$^[Equality only if all element-wise combinations of indices form a bijection/are unique.] 

This is all fairly intuitive, however, actually computing the indices of a product factor presents some challenges. A naive idea might be to simply sum/multiply pairs of indices element-wise, however, this approach does not work: the sum/product of two different pairs of indices might produce the same value (e.g. in a product of two factors with cardinalities of $2$ and $3$, there are two different ways to get $4$ as the sum of indices: $1 + 3$ and $2 + 2$). Further, when taking the product of two factors, we may want to preserve the factor order, in the sense that cases associated with lower values of the first factor should get assigned lower indices. Because sums and products are commutative, this does not work. 

One crude solution shown in Section \@ref(products-of-partitions) is to treat the factor indices as strings and concatenate them elementwise. This works, but produces an unnecessary computational overhead. There is a better way. Assuming we have two factors with cardinalities $c_1$ and $c_2$, and two indices $i_1$ and $i_2$ corresponding to the same case, we can compute the product index $i_{\text{product}}$ via the following formula:

\begin{align}
k &= \max(c_1, c_2) \\
i_{\text{product}} &= k \cdot i_{\text{1}} + i_{\text{2}}
(\#eq:product-indices)
\end{align}

This formula is similar to one discussed in  @wickham2013. Since $i_1$ and $i_2$ take values in $0 \ldots c_1 - 1$ and $0 \ldots c_2 - 1$, respectively^[Using zero-based indexing.], the product index is guaranteed to be unique: if $i_1 = 0$ then $i_{\text{product}} = i_2$, if $i_1 = 1$ then $i_{\text{product}} = k + i_2$, if $i_1 = 2$ then $i_{\text{product}} = 2k + i_2$, and so on. Further, since the the index corresponding to the first factor is multiplied by $k$, it intuitively gets assigned a greater "weight" and the relative order of the two factors is preserved. See for example Table \@ref(tab:product-indices) of product indices of two factors with cardinalities 2 and 3:

\begin{table}

\caption{(\#tab:product-indices)An example of product indices computed across two factors.}
\centering
\begin{tabular}[t]{rrr}
\toprule
Factor 1 index & Factor 2 index & Product index\\
\midrule
0 & 0 & 0\\
0 & 1 & 1\\
0 & 2 & 2\\
1 & 0 & 3\\
1 & 1 & 4\\
\addlinespace
1 & 2 & 5\\
\bottomrule
\end{tabular}
\end{table}

Finally, given a product index $i_{\text{product}}$, we can also recover the original indices (assuming $k$ is known):

\begin{align}
i_1 &= \lfloor i_{\text{product}} / k \rfloor \\
i_2 &= i_{\text{product}} \mod k
\end{align}

This is useful when constructing the product factor data: we need to take all unique product indices and use them to proxy the data of the original two factors.

It should be mentioned that, as with binning, computing product indices based on Equation \@ref(eq:product-indices) creates gaps. Again, `plotscape` solves this by keeping track of the unique product indices and looping over the indices again to "clean" them, in $O(n)$ time. Further, since we want to retain factor order, `plotscape` also sorts the unique product indices before running the second loop. Hypothetically, with $n$ data points, there can be up $n$ unique product indices (even when $c_1, c_2 < n$ both), and therefore this sorting operation makes creating and updating product indices have $O(n \cdot \log n)$ worst-case time complexity. However, I contend that, in the average case, the length of the unique product indices will be some smaller fraction of the length of the data. Further, profiling during development did not identify this operation as a performance bottleneck. However, if this sorting procedure did turn out to be a bottleneck at some point, there may be other more performant algorithms/data structures available^[For instance, one hypothetical option would be to store the computed product indices in a min-heap [see e.g. @cormen2022]. Min-heaps have a $O(\log n)$ time complexity for deleting the lowest element, which may seem like an improvement, however, to clean all indices, we would still need to delete all $n$ nodes, which would again result in $O(n \cdot \log n)$ time complexity, and therefore there would be little real advantage over sorting. Another option would be to simply trade time complexity for space complexity and maintain a "holey" array of all possible product indices with length $c_1 \cdot c_2$, which would only need to be compacted once all indices are computed.].

Finally, `Factor.product` is the only factor constructor which actually assigns to the `parent` property of the output `Factor`. Specifically, the first factor always gets assigned as the parent of the product, creating a hierarchical structure. Technically, there are situations where a product of two factors is simply a "flat" product and not a hierarchy. This is the case, for example, when taking the product of two binned variables in a 2D histogram - the two factors are conceptually equal. However, in practice, this distinction rarely matters. Any computation involving a flat product can simply ignore the `parent` property, and the data is for all other intents and purposes equivalent. This similarity of flat and hierarchical products was also noted by Wilkinson, who used the terminology of cross and nest operators [@wilkinson2012, pp. 61]. 

#### Marker

An important component which also serves the function of a `Factor` but deserves its own section is the `Marker`. `Marker` is used to represent group assignment during linked selection, making it a key component of `plotscape`. Moreover, while most of the components discussed so far can exist within the context of a single plot, `Marker` further differs by the fact that it is shared by all plots within the same figure.

`Marker` has the following `Factor`-like interface which will be gradually explained below^[The actual implementation in the current version of `plotscape` differs slightly in several key aspects, however, I chose to use this simplified interface here for clarity.]:


``` ts
interface Marker {
  cardinality: number;
  indices: number[];
  data: { layer: number[] };
  transientIndices: number[];
}
```

However, before delving into this interface, let's first discuss some important theoretical concepts related to `Marker`.

##### Transient vs. persistent selection {#transient-persistent}

A key concept in the implementation of `Marker` is the distinction between transient and persistent selection [see also @urbanek2011]. By default, `plotscape` plots are in transient selection mode, meaning that linked selection operations (e.g. clicking, clicking-and-dragging) assign cases the transient selection status. This transient selection status is cleared by subsequent selection events, as well as many other interactions including panning, zooming, representation switching, and change of parameters. To make the results of selection persist across these interactions, the user can assign cases to persistent selection groups (currently, this is down by holding down a numeric key and performing regular selection). Persistent selections are removed only by a dedicated action (double-click).

Importantly, a single data point can be simultaneously assigned to a persistent group *and* also be transiently selected. For example, a data point may belong to the base (unselected) group, transiently selected base group, persistent group one, transiently selected persistent group one, and so on. This means that `plotscape` has a very minimal version of selection operators [see @unwin1996; @theus2002] baked-in: transient and persistent selection are automatically combined via intersection (the `AND` operator). While a full range of selection operators provides much greater flexibility, I contend that this simple transient-persistent model already provides a lot of practical utility. Specifically, it enables a common action in the interactive data visualization workflow: upon identifying an interesting trend with selection, a user may be interested in how the trend changes when conditioning on *another* (`AND`) subset of the data. The transient-persistent model makes this possible, without introducing the overhead having to learn how to use various selection operators. 



































































